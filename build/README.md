This README will guide you through the several steps to build the `s3gw`
container image.

# Prerequisite
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

If the Ceph Git repository is stored in a different path, then this
can be customized via the `CEPH_DIR` environment variable.

# Build the build environment
To isolate the build system from your host, we provide a build environment
based on openSUSE Tumbleweed. This containerized build environment will
contain all necessary dependencies.

## Install management tool
To create the buidl environment, make sure to install all necessary
tools. This can be done by running the command:

```
$ cd ~/git/s3gw-core
$ sudo buildenvadm.sh install
```

## Create the build environment
To create the containerized build environment run the following
command:

```
$ cd ~/git/s3gw-core
$ buildenvadm.sh create
```

The source code of Ceph will be mounted to `/srv/ceph` and the
s3gw-core code is available at `/srv/s3gw-core`.

## Start the build environment
To start the build environment, run the following command:

```
$ cd ~/git/s3gw-core
$ buildenvadm.sh start
```

You will be redirected to the `/srv/s3gw-core/build` directory within
the containerized build environment.

# Building radosgw binary
If the binary is not compiled yet, simply run the following commands:

```
# cd ~/git/s3gw-core
# cd build
# ./build-radosgw.sh
```

If you are not running openSUSE Tumbleweed on your host, you can use
the `Dockerfile.build-s3gw` file to setup a container that will
automatically build the binary when the container is started.

```
$ cd ~/git/s3gw-core/build
$ podman build --tag build-s3gw -f ./Dockerfile.build-s3gw
```

To trigger a build run, execute the following commands:
```
$ cd ~/git/s3gw-core/build
$ podman run --replace --name build-s3gw -v ../../ceph:/srv/ceph/ localhost/build-s3gw 
```

# Build the container image
If the Ceph `radosgw` binary is compiled, the container image can be build
with the following commands:

```
# cd ~/git/s3gw-core
# cd build
# ./build-container.sh
```

The container build script expects the `radosgw` binary at the relative
path `../ceph/build/bin`.
