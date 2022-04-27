This documentation will guide you through the several steps to build the
`s3gw` container image.

> **NOTE:** The absolute paths mentioned in this document may be different
> on your system.

# Prerequisite
Make sure you've installed the following applications:

- podman
- buildah

Optionally, if you prefer building an `s3gw` container image with docker you will need:

- docker

The build scripts expect the following directory hierarchy.

```
|
|- ceph/
|  |- build/
|  ...
|
|- s3gw-core/
   |- build/
   ...
```

# Building radosgw binary
To build the `radosgw` binary, a containerized build environment is used.
This container can be build by running the following command:

```
$ cd ~/git/s3gw-core/build
$ podman build --tag build-radosgw -f ./Dockerfile.build-radosgw
```

If you experience connection issues while downloading the packages to be
installed in the build environment, try using the `--net=host`
command line argument.

After the build environment container image has been build once, the
`radosgw` binary will be build automatically when the container is
started. Make sure the path to the Ceph Git repository in the host
file system is correct, e.g. `../../ceph`, `~/git/ceph`, ...

```
$ podman run --replace --name build-radosgw -v ../../ceph/:/srv/ceph/ localhost/build-radosgw 
```

# Build the s3gw container image
If the Ceph `radosgw` binary is compiled, the container image can be build
with the following commands:

```
$ cd ~/git/s3gw-core/build
$ ./build-container.sh
```

By default, this will build an `s3gw` image using podman.
In order to build an `s3gw` image with Docker, you can run:

```
$ cd ~/git/s3gw-core/build
$ CONTAINER_ENGINE=docker ./build-container.sh
```

The container build script expects the `radosgw` binary at the relative
path `../ceph/build/bin`. This can be customized via the `CEPH_DIR`
environment variable.

The container image name is `s3gw` by default. This can be customized via
the environment variable `IMAGE_NAME`.

# Running the s3gw container
Finally, you can run the `s3gw` container with the following command:

```
$ podman run --replace --name=s3gw -it -p 7480:7480 localhost/s3gw
```

or, when using Docker:

```
$ docker run -p 7480:7480 s3gw
```