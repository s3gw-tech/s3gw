# s3tr - A S3 Test Runner

## What is this?

A tool to run [s3-tests](https://github.com/ceph/s3-tests)

- in containers
- in parallel
- with a fresh S3GW

During testing we collect:

- test logs
- S3GW logs
- S3GW metrics (via Prometheus status page)

Integrated analysis tools:

- Compare test results to a list of know failing tests for CI purposes
- Open results in a local [Datasette](https://datasette.io/) instance

## How does test execution work?

- 🧠 s3tr runner inside the s3tr container orchestrates:
  - for each s3 test divided onto N parallel worker process:
    - start a S3GW container
    - run `pytest` against that container
    - collect results
  - 📦 write a results JSON file

## Container Images

Live on GH in the [s3tr
container](https://github.com/aquarist-labs/s3gw/pkgs/container/s3tr)
registry.

Merging a PR triggers an action that builds and pushes a fresh image.

## Where do we use this?

- [PR CI pipeline](https://github.com/aquarist-labs/ceph/blob/s3gw/.github/workflows/test-s3gw.yml)
- On a developer machine

## Where do the s3-tests come from?

They are baked into the container image during build time. Versions
are pinned. See Dockerfile.

## Results JSON

Array of object. Each object contains the result of a single test.

Keys:

- `container_logs` - s3gw container logs
- `test_output` - pytest run logs
- `test_data` - pytest JSON report output. Contains test keywords and
  timing information from pytest json-report plugin
- `metrics`: Prometheus data scraped after the test run
- `test_return`: Success or failure from pytest
- `container_return`: Success of failure from container shutdown

## Usage Examples

### Test latest nightly

```sh
docker run \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -v$(readlink -f .):/out \
       ghcr.io/irq0/s3tr:latest \
       run \
       --image quay.io/s3gw/s3gw:nightly-latest \
       /out/nightly.json
```

### Run Datasette

```sh
docker run \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -v$(readlink -f .):/out \
       -p 8080:8080 ghcr.io/irq0/s3tr:latest \
       datasette serve \
       /out/nightly.json
```

## Developer Advanced Usage Examples

### Run a single test

```sh
docker run  \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -v $(readlink -f .):/out \
       ghcr.io/aquarist-labs/s3tr:latest \
       run \
       --image ghcr.io/irq0/s3tr:latest \
       --tests s3tests_boto3/functional/test_s3.py::test_copy_to_itself \
       /out/s3tr.json
```

`s3tests_boto3` is the path we pull the s3-tests in during image creation

### Run local build without creating a container

```sh
docker run \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -v$(readlink -f .):/out \
       ghcr.io/irq0/s3tr:latest \
       run \
       --image docker.io/opensuse/tumbleweed:latest \
       --extra-container-args '{
           "volumes": [
               "/usr:/usr:ro",
               "/compile:/compile:ro",
               "/bin:/bin:ro"
           ],
           "environment": [
               "PATH=/compile/s3gw/build_clang/bin:/bin:/usr/bin"
           ]}' \
       /out/s3tr.json

```

This works by mapping the local system's binary, library and build -
`/compile` - paths over a container image.

Adding our build directory's `bin` to the front of `PATH` causes s3tr
to run the `radosgw` binary from there.

To adapt this to your local developer environment change `/compile`
and `/compile/s3gw/build_clang`.
