# How to build your own containers

## Building the s3gw container image

This documentation will guide you through the several steps to build the
`s3gw` container image.

> **NOTE:** The absolute paths mentioned in this document may be different
> on your system.

### Prerequisites

Make sure you've installed the following applications:

- podman
- buildah

Optionally, if you prefer building an `s3gw` container image with Docker you
will need:

- docker

The build scripts expect the following directory hierarchy.

```text
|
|- ceph/
|  |- build/
|  ...
|
|- s3gw-core/
   |- build/
   ...
```

### Building the radosgw binary

To build the `radosgw` binary, a containerized build environment is used.
This container can be built by running the following command:

```shell
cd ~/git/s3gw-core/build
podman build --tag build-radosgw -f ./Dockerfile.build-radosgw
```

If you experience connection issues while downloading the packages to be
installed in the build environment, try using the `--net=host`
command line argument.

After the build environment container image has been build once, the
`radosgw` binary will be build automatically when the container is
started. Make sure the path to the Ceph Git repository in the host
file system is correct, e.g. `../../ceph`, `~/git/ceph`, ...

```shell
podman run \
  --replace \
  --name build-radosgw \
  -v ../../ceph/:/srv/ceph/ \
  localhost/build-radosgw
```

By default, the `radosgw` binary file will be build in `Debug` mode. For
production builds set the environment variable `CMAKE_BUILD_TYPE` to `Release`,
`RelWithDebInfo` or `MinSizeRel`. Check the [CMAKE_BUILD_TYPE documentation][1]
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

If the Ceph `radosgw` binary is compiled, the container image can be build
with the following commands:

```shell
cd ~/git/s3gw-core/build
./build-container.sh
```

By default, this will build an `s3gw` image using podman.
In order to build an `s3gw` image with Docker, you can run:

```shell
cd ~/git/s3gw-core/build
CONTAINER_ENGINE=docker ./build-container.sh
```

The container build script expects the `radosgw` binary at the relative
path `../ceph/build/bin`. This can be customized via the `CEPH_DIR`
environment variable.

The container image name is `s3gw` by default. This can be customized via
the environment variable `IMAGE_NAME`.

### Running the s3gw container

Finally, you can run the `s3gw` container with the following command:

```shell
podman run --replace --name=s3gw -it -p 7480:7480 localhost/s3gw
```

or, when using Docker:

```shell
docker run -p 7480:7480 localhost/s3gw
```

By default, the container will run with the following arguments:

```text
--rgw-backend-store dbstore
--debug-rgw 1
```

You can override them passing different values when starting the container.
For example if you want to increase `radosgw` logging verbosity, you could run:

```shell
podman run -p 7480:7480 localhost/s3gw --rgw-backend-store dbstore --debug-rgw 15
```

[1]: https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html
