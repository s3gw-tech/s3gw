# s3gw core

S3-compatible Gateway based on Ceph RGW, using a non-RADOS backend for
standalone usage.

This project shall provide the required infrastructure to build a container
able to run on a kubernetes cluster, providing S3-compatible endpoints to
applications.

Table of Contents
=================

* [Roadmap](#roadmap)
* [How To](#how-to)
  * [Introduction](#introduction)
  * [Requirements](#requirements)
  * [Running](#running)
* [Building the s3gw container image](#building-the-s3gw-container-image)
  * [Prerequisites](#prerequisites)
  * [Building the radosgw binary](#building-the-radosgw-binary)
  * [Build the s3gw container image](#build-the-s3gw-container-image)
  * [Running the s3gw container](#running-the-s3gw-container)
* [Building the s3gw-UI image](#building-the-s3gw-ui-image)
* [Building and running a complete environment](#building-and-running-a-complete-environment)
* [When things don't work](#when-things-dont-work)
* [License](#license)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

## Roadmap

We are currently focusing on delivering a proof-of-concept, demonstrating the
feasibility of the project. We call this deliverable the Minimum Viable Product.

The image below represents what we believe to be our current roadmap. We are on
the MVP phase right now. Once we achieve this deliverable, and depending on user
feedback being positive, amongst other factors that may yet be determined, we
shall proceed to the next phase of development.

![S3GW Roadmap](/assets/images/s3gw-roadmap.jpg)

We also keep track of our items in an Aquarist Labs organization dedicated
[project](https://github.com/orgs/aquarist-labs/projects/5/views/1).

## How To

### Introduction

Given we are still setting up the project, figuring out requirements, and
specific details about direction, we are dedicating most of our efforts to
testing Ceph's RGW as a standalone daemon using a non-RADOS storage backend.

The backend in question is called `dbstore`, backed by a SQLite database, and
is currently provided by RGW.

In order to ensure we all test from the same point in time, we have a forked
version of the latest development version of Ceph, which can be found
[here](https://github.com/aquarist-labs/ceph.git). We are working using the
[`s3gw` branch](https://github.com/aquarist-labs/ceph/tree/s3gw) as our base of
reference.

Keep in mind that this development branch will likely closely follow Ceph's
upstream main development branch, and is bound to change over time. We intend
to contribute whatever patches we come up with to the original project, thus
we need to keep up with its ever evolving state.

### Requirements

We are relying on built Ceph sources to test RGW. We don't have a particular
preference on how one achieves this. Some of us rely on containers to build
these sources, while others rely on whatever OS they have on their local
machines to do so. Eventually we intend to standardize how we obtain the
RGW binary, but that's not in our immediate plans.

If one is new to Ceph development, the best way to find out how to build
these sources is to refer to the
[original documentation](https://docs.ceph.com/en/pacific/install/build-ceph/#id1).

Because we are in a fast development effort at the moment, we have chosen to
apply patches needed to make our endeavour work on our own fork of the Ceph
repository. This allows us fiddle with the Ceph source while experimenting,
without polluting the upstream Ceph repository. We do intend to upstream any
patches that make sense though.

That said, we have the `aquarist-labs/ceph` repository as a requirement for
this project. We can't guarantee that our instructions, or the project as a
whole, will work flawlessly with the original Ceph project from `ceph/ceph`.

### Running

One should be able to get a standalone RGW running following these steps:

```
$ cd build/
$ mkdir -p dev/rgw.foo
$ bin/radosgw -i foo -d --no-mon-config --debug-rgw 15 \
    --rgw-backend-store dbstore \
    --rgw-data $(pwd)/dev/rgw.foo \
    --run-dir $(pwd)/dev/rgw.foo
```

Once the daemon is running, and outputting its logs to the terminal, one can
start issuing commands to the daemon. We rely on `s3cmd`, which can be found
on [github](https://github.com/s3tools/s3cmd) or obtained through `pip`.

`s3cmd` will require to be configured to talk to RGW. This can be achieved by
first running `s3cmd -c $(pwd)/.s3cfg --configure`. By default, the configuration
file would be put under the user's home directory, but for our testing purposes
it might be better to place it somewhere less intrusive.

During the interactive configuration a few things will be asked, and we
recommend using these answers unless one's deployment is different, in which
case these will need to be properly adapted.

```
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

## Building the s3gw container image

This documentation will guide you through the several steps to build the
`s3gw` container image.

> **NOTE:** The absolute paths mentioned in this document may be different
> on your system.

### Prerequisites
Make sure you've installed the following applications:

- podman
- buildah

Optionally, if you prefer building an `s3gw` container image with Docker you will need:

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

### Building the radosgw binary
To build the `radosgw` binary, a containerized build environment is used.
This container can be built by running the following command:

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

By default, the `radosgw` binary file will be build in `Debug` mode. For production
builds set the environment variable `CMAKE_BUILD_TYPE` to `Release`, `RelWithDebInfo`
or `MinSizeRel`. Check the [CMAKE_BUILD_TYPE documentation](https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html)
for more information.

```
$ podman run --replace --name build-radosgw -e CMAKE_BUILD_TYPE="MinSizeRel" -v ../../ceph/:/srv/ceph/ localhost/build-radosgw
```

### Build the s3gw container image
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

### Running the s3gw container
Finally, you can run the `s3gw` container with the following command:

```
$ podman run --replace --name=s3gw -it -p 7480:7480 localhost/s3gw
```

or, when using Docker:

```
$ docker run -p 7480:7480 localhost/s3gw
```
By default, the container will run with the following arguments:

```text
--rgw-backend-store dbstore
--debug-rgw 1
```

You can override them passing different values when starting the container.
For example if you want to increase `radosgw` logging verbosity, you could run:

```shell
$ podman run -p 7480:7480 localhost/s3gw --rgw-backend-store dbstore --debug-rgw 15
```

## Building the s3gw-UI image

You can refer to the [build-ui](./build-ui/) section to build the s3gw-UI image.

## Building and running a complete environment

You can refer to the [environment](./env/) section to build a fully provisioned Kubernetes cluster.

## When things don't work

If one finds a problem, as one is bound to at this point in time, we encourage
everyone to check out our [issues list](https://github.com/aquarist-labs/s3gw-core/issues)
and either file a new issue if the observed behavior has not been reported
yet, or to contribute with further details to an existing issue.

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use licensed files except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

or the LICENSE file in this repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

