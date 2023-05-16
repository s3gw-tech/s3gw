#!/usr/bin/env python3
"""
A s3-tests runner tailored to s3gw containers with parallel execution,
result and log gathering
"""

import io
import json
import logging
import multiprocessing
import os
import pathlib
import random
import subprocess
import sys
import tarfile
import tempfile
import time
from contextlib import suppress

import click
import docker
import radosgw
import requests

LOG = logging.getLogger("s3tr")

# How long an individual pytest may run in seconds
PYTEST_TIMEOUT_SEC = 100

# From vstart.sh::do_rgw_create_users
S3TESTS_USERS = {
    "s3 main": {
        "uid": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        "access_key": "ABCDEFGHIJKLMNOPQRST",
        "secret_key": "abcdefghijklmnopqrstuvwxyzabcdefghijklmn",
        "display_name": "youruseridhere",
        "email": "s3@example.com",
        "user_caps": "user-policy=*",
    },
    "s3 alt": {
        "uid": "56789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234",
        "access_key": "NOPQRSTUVWXYZABCDEFG",
        "secret_key": "nopqrstuvwxyzabcdefghijklmnabcdefghijklm",
        "display_name": "john.doe",
        "email": "john.doe@example.com",
    },
    "s3 tenant": {
        "uid": "9876543210abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        "access_key": "HIJKLMNOPQRSTUVWXYZA",
        "secret_key": "opqrstuvwxyzabcdefghijklmnopqrstuvwxyzab",
        "display_name": "testx$tenanteduser",
        "email": "tenanteduser@example.com",
    },
}


def make_radosgw_command(id, port):
    return [
        "stdbuf",
        "-oL",
        "radosgw",
        "-d",
        "--no-mon-config",
        "--id",
        id,
        "--rgw-data",
        "/data",
        "--run-dir",
        "/run/",
        "--rgw-sfs-data-path",
        "/data",
        "--rgw-s3gw-telemetry-update-interval",
        "0",
        "--rgw-backend-store",
        "sfs",
        "--rgw-enable-ops-log",
        "0",
        "--rgw-log-object-name",
        "0",
        "--rgw-crypt-require-ssl",
        "0",
        "--rgw_crypt_s3_kms_backend",
        "testing",
        "--rgw_crypt_s3_kms_encryption_keys",
        "testkey-1=YmluCmJvb3N0CmJvb3N0LWJ1aWxkCmNlcGguY29uZgo= "
        "testkey-2=aWIKTWFrZWZpbGUKbWFuCm91dApzcmMKVGVzdGluZwo=",
        "--rgw_crypt_default_encryption_key",
        "4YSmvJtBv0aZ7geVgAsdpRnLBEwWSWlMIGnRS8a9TSA=",
        "--rgw-lc-debug-interval",
        "10",
        "--log-flush-on-exit",
        "1",
        "--log-to-stderr",
        "1",
        "--err-to-stderr",
        "1",
        "--log-max-recent",
        "1",
        "--debug-rgw",
        "10",
        "--rgw-frontends",
        f'"beast port={port}"',
        "2>&1 1> /log",
    ]


class S3GW:
    """
    An S3GW container.

    Lifecycle: start(), stop(), remove()
    Resources: logs(), logfile(), network_address()
    Status: http_up()
    Admin OPs: create_user()
    """

    def __init__(self, cri, image, container_run_args, name, port):
        self.cri = cri
        self.image = image
        self.container_run_args = container_run_args
        self.name = name
        self.port = port
        self.container = None

    def start(self):
        command = make_radosgw_command(self.name, self.port)
        kwargs = self.container_run_args | {
            "image": self.image,
            "name": f"s3gw_{self.name}",
            "detach": True,
            "stop_signal": "SIGTERM",
            "labels": ["s3gw_s3tests"],
            "entrypoint": "/bin/sh",
            "command": ["-c", " ".join(command)],
        }
        container = self.cri.containers.run(**kwargs)
        LOG.debug(
            "running s3gw container %s with %r status %s",
            container.name,
            kwargs,
            container.status,
        )
        assert container.status != "exited"
        self.container = container
        self.container.reload()

    def network_address(self):
        for retry in range(5):
            addr = self.container.attrs["NetworkSettings"]["IPAddress"]
            if addr:
                return addr
            time.sleep(2 * (retry + 1))
            self.container.reload()
        raise RuntimeError(
            f"Container has no network address after {retry} tries. "
            "Startup failed? "
            "Check container logs."
        )

    def http_up(self):
        try:
            resp = requests.head(f"http://{self.network_address()}:{self.port}")
            return resp.ok
        except requests.exceptions.ConnectionError:
            return False

    def create_user(self, **kwargs):
        rgwadmin = radosgw.connection.RadosGWAdminConnection(
            host=self.network_address(),
            port=self.port,
            access_key="test",
            secret_key="test",
            is_secure=False,
        )
        return rgwadmin.create_user(**kwargs)

    def logs(self):
        # container.logs() not 100% reliably get the logs right away.
        # sometimes only after a minute or so..
        for retry in range(20):
            logs = self.container.logs()
            if logs:
                return logs.decode("utf-8")
            LOG.info(f"no logs for {self.container} after {retry} tries")
            time.sleep(2 * (retry + 1))
        LOG.warning(
            f"no logs for {self.container} after 20 retries. returning not available"
        )
        return "not available"

    def logfile(self):
        # reliable but slow alternative to logs(). needs the container
        # to write to /logs
        with tempfile.NamedTemporaryFile() as fp:
            try:
                bits, stat = self.container.get_archive("/log")
                for chunk in bits:
                    fp.write(chunk)
            except docker.errors.NotFound:
                LOG.error("logfile not found")
                return "not found"
            fp.seek(0)
            log = io.BytesIO()
            with tarfile.open(fp.name) as tf:
                for entry in tf:
                    fp = tf.extractfile(entry)
                    if not fp:
                        continue
                    log.write(fp.read())
                    break
            log.seek(0)
            return log.getvalue().decode("utf-8")

    def stop(self):
        LOG.debug(
            "s3gw stopping container %s. was in state %s",
            self.container,
            self.container.status,
        )

        if self.container.status not in ("running", "created"):
            return "crash"
        else:
            with suppress(docker.errors.APIError):
                self.container.stop(timeout=10)
            return "success"

    def remove(self):
        with suppress(docker.errors.APIError):
            self.container.remove()


def get_tests(s3_tests_path, search_string):
    result = []
    out = subprocess.check_output(
        [
            "pytest",
            "--collect-only",
            "-q",
            "--disable-warnings",
            "--no-header",
            "--no-summary",
            search_string,
        ],
        cwd=s3_tests_path,
    )
    for line in out.decode("utf-8").split("\n"):
        if line.startswith("s3tests"):
            result.append(line.strip())
    return result


def mk_config(host, port, users):
    return f"""
[DEFAULT]
host = {host}
port = {port}
is_secure = False
ssl_verify = False

[fixtures]
bucket prefix = sfstest-{{random}}-

[s3 main]
display_name = {users['s3 main']['display_name']}
user_id = {users['s3 main']['uid']}
email = {users['s3 main']['email']}
access_key = {users['s3 main']['access_key']}
secret_key = {users['s3 main']['secret_key']}
api_name = default
lc_debug_interval = 10

[s3 alt]
display_name = {users['s3 alt']['display_name']}
user_id = {users['s3 alt']['uid']}
email = {users['s3 alt']['email']}
access_key = {users['s3 alt']['access_key']}
secret_key = {users['s3 alt']['secret_key']}

[s3 tenant]
display_name = {users['s3 tenant']['display_name']}
user_id = {users['s3 tenant']['uid']}
email = {users['s3 tenant']['email']}
access_key = {users['s3 tenant']['access_key']}
secret_key = {users['s3 tenant']['secret_key']}

[iam]
email = s3@example.com
user_id = testid
access_key = test
secret_key = test
display_name = youruseridhere
    """


def run_test(docker_api, image, container_run_args, s3_tests, name, port):
    start_time_ns = time.perf_counter_ns()
    cri = docker.DockerClient(base_url=docker_api)
    container_name = name.split("::")[1]
    container = S3GW(cri, image, container_run_args, container_name, port)
    container.start()

    for retry in range(10):
        if container.http_up():
            break
        time.sleep(1 * retry)

    if not container.http_up():
        return {
            "test": name,
            "test_return": "fail",
            "container_return": "fail",
            "container_logs": container.logfile(),
            "test_output": "",
            "test_data": "",
            "runtime_ns": time.perf_counter_ns() - start_time_ns,
        }

    for user in S3TESTS_USERS.values():
        ret = container.create_user(**user)
        LOG.debug(f"Created test user: {ret}")

    with tempfile.NamedTemporaryFile() as config_fp, \
         tempfile.NamedTemporaryFile() as json_out_fp:  # fmt: skip
        config_fp.write(
            mk_config(container.network_address(), port, S3TESTS_USERS).encode("ascii")
        )
        config_fp.flush()
        try:
            cmd = [
                "pytest",
                "-v",
                "--json-report",
                f"--json-report-file={json_out_fp.name}",
                "--",
                name,
            ]
            env = dict(**os.environ)
            env["S3TEST_CONF"] = config_fp.name
            LOG.debug(f"running {cmd} with {env} cwd {s3_tests}")
            proc = subprocess.run(
                cmd,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=PYTEST_TIMEOUT_SEC,
                cwd=s3_tests,
                env=env,
            )
            ret = "success"
            out = proc.stdout.decode("utf-8")
            data_out = json.load(json_out_fp)["tests"][0]
        except subprocess.CalledProcessError as e:
            ret = "fail"
            out = e.output.decode("utf-8")
            data_out = json.load(json_out_fp)["tests"][0]
        except subprocess.TimeoutExpired as e:
            ret = "timeout"
            out = e.output.decode("utf-8")
            try:
                data_out = json.load(json_out_fp)["tests"][0]
            except Exception:
                data_out = {}
        except Exception as e:
            LOG.exception("unhandled exception during test %s. rethrowing.", name)
            raise e

    container_ret = container.stop()
    logs = container.logfile()
    container.remove()
    return {
        "test": name,
        "test_return": ret,
        "container_return": container_ret,
        "container_logs": logs,
        "test_output": out,
        "test_data": data_out,
        "runtime_ns": time.perf_counter_ns() - start_time_ns,
    }


def run_test_unpack(args):
    return run_test(*args)


def run_tests(docker_api, image, container_run_args, s3_tests, nproc, tests):
    start_port = 10000
    jobs = [
        (docker_api, image, container_run_args, s3_tests, test, start_port + i)
        for i, test in enumerate(tests)
    ]
    results = []
    with multiprocessing.Pool(nproc) as pool:
        for result in pool.imap_unordered(run_test_unpack, jobs, chunksize=1):
            results.append(result)
            if (len(results) % 10) == 0:
                mean_runtime_ns = int(
                    sum(r["runtime_ns"] for r in results) / len(results)
                )
                estimated_time_left_ns = int(
                    mean_runtime_ns * (len(jobs) - len(results)) / nproc
                )
                LOG.info(
                    f"{len(results)}/{len(jobs)} done. "
                    f"mean runtime {int(mean_runtime_ns/10**9)}s. "
                    f"estimated time left {int(estimated_time_left_ns/10**9)}s. "
                )
    return results


def cleanup(cri):
    LOG.info("Cleaning up")
    for _ in range(3):
        try:
            for c in cri.containers.list(all=True, filters={"label": "s3gw_s3tests"}):
                LOG.debug(f"Removing container {c}")
                c.stop(timeout=2)
                c.remove()
        except Exception:
            continue


class JSONParamType(click.ParamType):
    name = "JSON"

    def convert(self, value, param, ctx):
        try:
            return json.loads(value)
        except json.JSONDecodeError as e:
            self.fail(f"{value!r} is not valid JSON: {e}", param, ctx)


@click.command()
@click.option(
    "--docker-api",
    type=str,
    envvar="DOCKER_API",
    default="unix:///var/run/docker.sock",
    help="Docker API URI. e.g unix://run/podman/podman.sock",
)
@click.option(
    "--tests",
    type=str,
    default="s3tests_boto3/functional/test_s3.py",
    help="pytest search string / path e.g s3tests_boto3/functional/test_s3.py",
)
@click.option(
    "--nproc",
    type=int,
    default=42,
    help="processing pool size",
)
@click.option(
    "--sample",
    type=int,
    default=0,
    help="> 0 run random sample of tests",
)
@click.option(
    "--image",
    type=str,
    default="quay.io/s3gw/s3gw:latest",
)
@click.option(
    "--s3-tests",
    envvar="S3TESTS",
    type=click.Path(
        file_okay=False, dir_okay=True, allow_dash=False, path_type=pathlib.Path
    ),
)
@click.option(
    "--extra-container-args",
    help=(
        "Extra keyword arguments to pass to container.run as JSON object"
        "(See https://docker-py.readthedocs.io/en/stable/containers.html#"
        "docker.models.containers.ContainerCollection.run)"
    ),
    type=JSONParamType(),
    default="{}",
)
@click.argument("output", type=click.File("w"))
def run(
    docker_api, tests, nproc, sample, image, s3_tests, output, extra_container_args
):
    """
    Run all or selected (--tests) s3tests against s3gw container image (--image)
    using a Docker compatible API endpoint (--docker-api).
    """
    if (
        docker_api.startswith("unix")
        and not pathlib.Path(docker_api[len("unix:") :]).exists()
    ):
        LOG.critical(
            f"Docker API set to unix socket ({docker_api}), "
            "but file does not exist. Add docker volume?"
        )
        sys.exit(2)

    tests = get_tests(s3_tests, tests)
    if sample > 0:
        tests = random.sample(tests, sample)
    LOG.debug(f"Running {len(tests)} tests: {tests}")
    LOG.info(
        f"Running {nproc} tests in parallel against "
        f"image {image} "
        f"with docker API {docker_api} "
        f"with s3-tests in {s3_tests}"
    )
    LOG.info(
        'Running radosgw with command "%s"',
        " ".join(make_radosgw_command("PLACEHOLDER", "PLACEHOLDER")),
    )
    try:
        results = run_tests(
            docker_api, image, extra_container_args, s3_tests, nproc, tests
        )
        LOG.info(f"Done. Ran {len(results)} tests.")
        json.dump(results, output)
        output.flush()
        LOG.info(f"Writing results to {output}")
    finally:
        cleanup(docker.DockerClient(base_url=docker_api))


if __name__ == "__main__":
    run()
