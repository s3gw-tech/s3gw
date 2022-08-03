# Developing the S3 Gateway

You can refer to the [development](./docs/development.md) section to understand
how to build the `s3gw` container image.

## Introduction

Given we are still setting up the project, figuring out requirements, and
specific details about direction, we are dedicating most of our efforts to
testing Ceph's RGW as a standalone daemon using a non-RADOS storage backend.

The backend in question is called `dbstore`, backed by a SQLite database, and is
currently provided by RGW.

In order to ensure we all test from the same point in time, we have a forked
version of the latest development version of Ceph, which can be found [here][1].
We are working using the [`s3gw` branch][2] as our base of reference.

Keep in mind that this development branch will likely closely follow Ceph's
upstream main development branch, and is bound to change over time. We intend
to contribute whatever patches we come up with to the original project, thus
we need to keep up with its ever evolving state.

## Requirements

We are relying on built Ceph sources to test RGW. We don't have a particular
preference on how one achieves this. Some of us rely on containers to build
these sources, while others rely on whatever OS they have on their local
machines to do so. Eventually we intend to standardize how we obtain the
RGW binary, but that's not in our immediate plans.

If one is new to Ceph development, the best way to find out how to build
these sources is to refer to the [original documentation][3].

Because we are in a fast development effort at the moment, we have chosen to
apply patches needed to make our endeavour work on our own fork of the Ceph
repository. This allows us fiddle with the Ceph source while experimenting,
without polluting the upstream Ceph repository. We do intend to upstream any
patches that make sense though.

That said, we have the `aquarist-labs/ceph` repository as a requirement for
this project. We can't guarantee that our instructions, or the project as a
whole, will work flawlessly with the original Ceph project from `ceph/ceph`.

## Running the Gateway

One should be able to get a standalone Gateway running following these steps:

```shell
cd build/
mkdir -p dev/rgw.foo
bin/radosgw -i foo -d --no-mon-config --debug-rgw 15 \
  --rgw-backend-store dbstore \
  --rgw-data $(pwd)/dev/rgw.foo \
  --run-dir $(pwd)/dev/rgw.foo
```

Once the daemon is running, and outputting its logs to the terminal, one can
start issuing commands to the daemon. We rely on `s3cmd`, which can be found
on [github][4] or obtained through `pip`.

`s3cmd` will require to be configured to talk to RGW. This can be achieved by
first running `s3cmd -c $(pwd)/.s3cfg --configure`. By default, the
configuration file would be put under the user's home directory, but for our
testing purposes it might be better to place it somewhere less intrusive.

During the interactive configuration a few things will be asked, and we
recommend using these answers unless one's deployment is different, in which
case these will need to be properly adapted.

```text
  Access Key: 0555b35654ad1656d804
  Secret Key: h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q==
  Default Region: US
  S3 Endpoint: 127.0.0.1:7480
  DNS-style bucket+hostname:port template for accessing a bucket: 127.0.0.1:7480/%(bucket)
  Encryption password: ****
  Path to GPG program: /usr/bin/gpg
  Use HTTPS protocol: False
  HTTP Proxy server name:
  HTTP Proxy server port: 0
```

Please note that both the `Access Key` and the `Secret Key` need to be copied
verbatim. Unfortunately, at this time, the `dbstore` backend statically creates
an initial user using these values.

Should the configuration be correct, one will then be able to issue commands
against the running RGW. E.g., `s3cmd mb s3://foo`, to create a new bucket.

[1]: https://github.com/aquarist-labs/ceph.git
[2]: https://github.com/aquarist-labs/ceph/tree/s3gw
[3]: https://docs.ceph.com/en/pacific/install/build-ceph/#id1
[4]: https://github.com/s3tools/s3cmd
