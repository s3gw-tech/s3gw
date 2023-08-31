# Developing the S3 Gateway

## Introduction

This project is exploring the use of Ceph's Rados Gateway (RGW) as a standalone
daemon with a non-RADOS storage backend. The backend, `dbstore`, is
backed by a SQLite database and is currently provided by RGW.

In order to ensure tests are conducted from the same point in time, a forked
version of the latest development version of Ceph is available [here][1].
The team uses the [`s3gw` branch][2] as our base of reference.

Keep in mind that this development branch will closely follow Ceph's
upstream main development branch, and is bound to change over time. We intend to
contribute whatever patches we come up with to the original project, thus we
need to keep up with its ever evolving state.

## Requirements

We are relying on built Ceph sources to test RGW. We don't have a particular
preference on how to achieve this. The team intends to standardize how
to obtain the RGW binary, but that's not in the immediate plans. For now,
there are two key options available:

1. Containers to build these sources
2. Local OS

If you are new to Ceph development, the best way to find out how to build these
sources is to refer to the [original Ceph documentation][3].

The `aquarist-labs/ceph` repository  is a requirement for this project.
We can't guarantee that our instructions, or the project as a whole,
will work flawlessly with the original Ceph project from `ceph/ceph`.

The team is in a fast development effort at the moment, patches to the
Ceph code are made against our own fork of the Ceph repository, allowing
us to experiment with the Ceph source and not pollute the upstream Ceph
repository. We do intend to upstream any patches that make sense though.

We rely on `s3cmd`, which can be found on [Github][4] or obtained through `pip`.

`s3cmd` needs to be configured to talk to RGW. This can be achieved by
first running `s3cmd -c $(pwd)/.s3cfg --configure`. By default, the
configuration file is put under the user's home directory, but for our
testing purposes we recommend to place it somewhere less intrusive.

## Running the Gateway

To get a standalone Gateway running, follow these steps:

```shell
cd build/
mkdir -p dev/rgw.foo
bin/radosgw -i foo -d --no-mon-config --debug-rgw 15 \
  --rgw-backend-store sfs \
  --rgw-data $(pwd)/dev/rgw.foo \
  --run-dir $(pwd)/dev/rgw.foo \
  --rgw-sfs-data-path $(pwd)/dev/rgw.foo
```

Once the daemon is running and outputting its logs to the terminal,
start issuing commands to the daemon.

During the interactive configuration there are prompts with questions. We
recommend using the following answers unless the deployment differs significantly.

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

Note that both the `Access Key` and the `Secret Key` need to be copied
verbatim. At this time, the `dbstore` backend statically creates
an initial user using these values.

Should the configuration be correct, you should be able to issue commands
against the running RGW. E.g., `s3cmd mb s3://foo`, to create a new bucket.

<!--- Probably should think about some troubleshooting docs for the above (A.S) -->

[1]: https://github.com/aquarist-labs/ceph.git
[2]: https://github.com/aquarist-labs/ceph/tree/s3gw
[3]: https://docs.ceph.com/en/pacific/install/build-ceph/#id1
[4]: https://github.com/s3tools/s3cmd

## How to build your own containers

### Building the s3gw container image

This documentation guides you through the steps to build the `s3gw` container image.

> **NOTE:** The absolute paths mentioned in this document may be different on
> your system.

### Prerequisites

Make sure you've installed the following applications:

- podman
- buildah

Optionally, if you prefer building an `s3gw` container image with Docker you
will need:

- docker

The build scripts expect the following directory hierarchy.

```text
|- s3gw/
   |- ceph/
   |  |- build/
   |  ...
   |
   |- tools/
      |- build/
   ...
```

### Building the radosgw binary

To build the `radosgw` binary, a containerized build environment is used. This
container can be built by running the following command:

```shell
cd ~/git/s3gw/tools/build
podman build --tag build-radosgw -f ./Dockerfile.build-radosgw
```

If you experience connection issues while downloading the packages to be
installed in the build environment, try using the `--net=host` command line
argument.

After the build environment container image has been built, the `radosgw`
binary can be built automatically anytime the container is started. Make sure the
path to the Ceph Git repository in the host file system is correct, e.g.
`../../ceph`, `~/git/ceph`, ...

```shell
podman run \
  --replace \
  --name build-radosgw \
  -v ../../ceph/:/srv/ceph/ \
  localhost/build-radosgw
```

By default, the `radosgw` binary file is built in `Debug` mode. For
production builds, set the environment variable `CMAKE_BUILD_TYPE` to `Release`,
`RelWithDebInfo` or `MinSizeRel`. Check the [CMAKE_BUILD_TYPE documentation][5]
for more information.

```shell
podman run \
  --replace \
  --name build-radosgw \
  -e CMAKE_BUILD_TYPE="MinSizeRel" \
  -v ../../ceph/:/srv/ceph/ \
  localhost/build-radosgw
```

### Build the s3gw container image

If the Ceph `radosgw` binary is compiled, the container image can be build with
the following commands:

```shell
cd ~/git/s3gw/tools/build
./build-container.sh
```

By default, this builds an `s3gw` image using podman. In order to build an
`s3gw` image with Docker, you can run:

```shell
cd ~/git/s3gw/tools/build
CONTAINER_ENGINE=docker ./build-container.sh
```

The container build script expects the `radosgw` binary at the relative path
`../ceph/build/bin`. This can be customized via the `CEPH_DIR` environment
variable.

The container image name is `s3gw` by default. This can be customized via the
environment variable `IMAGE_NAME`.

### Running the s3gw container

Finally, run the `s3gw` container with the following command:

```shell
podman run --replace --name=s3gw -it -p 7480:7480 localhost/s3gw
```

or, when using Docker:

```shell
docker run -p 7480:7480 localhost/s3gw
```

By default, the container runs with the following arguments:

```text
--rgw-backend-store dbstore
--debug-rgw 1
```

You can override them passing different values when starting the container. For
example if you want to increase `radosgw` logging verbosity, you could run:

```shell
podman run -p 7480:7480 localhost/s3gw --rgw-backend-store dbstore --debug-rgw 15
```

[5]: https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html

### Building the radosgw test binaries

A number of binaries implementing various tests for radosgw can be built.
Such binaries are focalized for testing specific radosgw implementation employed
for s3gw project.

You can build them by executing:

```shell
podman run \
  --replace \
  --name build-radosgw \
  -e WITH_TESTS="ON" \
  -v ../../ceph/:/srv/ceph/ \
  localhost/build-radosgw
```

### Build the s3gw-test container image

If the test binaries are compiled, a container image can be built with
the following commands:

```shell
cd ~/git/s3gw/tools/build
./build-radosgw-test-container.sh
```

By default, this builds an `s3gw-test` image using podman.
In order to build an `s3gw-test` image with Docker, you can run:

```shell
cd ~/git/s3gw/tools/build
CONTAINER_ENGINE=docker ./build-radosgw-test-container.sh
```

The container build script expects the test binaries at the relative path
`../ceph/build/bin`. This can be customized via the `CEPH_DIR` environment
variable.

The container image name is `s3gw-test` by default.
This can be customized via the environment variable `IMAGE_NAME`.

### Running the s3gw-test container

Finally, you can run the `s3gw-test` container with the following command:

```shell
podman run localhost/s3gw-test
```

or, when using Docker:

```shell
docker run -p 7480:7480 localhost/s3gw-test
```

## Building a s3gw-ui application image

This documentation guides you through the several steps to build a `s3gw-ui`
application image. With `s3gw-ui` image, we are referring at a generic term
indicating an image containing an application used to provide a UI related with
the `s3gw` project.

### Conventions

The `s3gw-ui` application is associated with a `Dockerfile` and adheres to the
following conventions:

- Dockerfile build context must be placed inside a directory placed alongside to
  the `s3gw-ui` project.
- You should be able to build that application from that directory with:

```text
npm install
npm run build
```

The `s3gw-ui` application should be consumable by `node` after it has been built.

<!-- markdownlint-disable-next-line no-duplicate-heading -->
### Prerequisites

Make sure you've installed the following applications:

- Podman

The build script expects the following directory hierarchy.

```text
|
|- s3gw-ui/
|  |- package.json
|  ...
|
|- s3gw/tools/
   |- build-ui/
   ...
```

### Build the application

Before building the `s3gw-ui` image you need to build the container image that
is used to compile the Angular based application. To do so, run:

```shell
cd ~/git/s3gw/tools/build-ui
./build.sh builder-image
```

This needs to be done once. After that you can build a `s3gw-ui` image by
running the following commands:

```shell
cd ~/git/s3gw/tools/build-ui
./build.sh app
./build.sh app-image
```

### Running the application

The user interface is running on port 8080 by default.

You can run a `s3gw-ui` application with:

```shell
podman run --replace --name=s3gw-ui -it -p 8080:8080 localhost/s3gw-ui
```

### Configuration

To configure the application at runtime the following environment variables are
available:

- RGW_SERVICE_URL

  This variable allows you to configure the URL to the RGW service.

  ```shell
  podman run --name=s3gw-ui ... -e RGW_SERVICE_URL=https://foo.bar:7480 localhost/s3gw-ui
  ```

  Keep in mind that the browser will report errors related to CORS if the
  RGW is running on a different URL or port and self-signed SSL certificates are
  used. In most cases, this can be fixed by visiting the URL of the RGW to accept
  the SSL certificate.
