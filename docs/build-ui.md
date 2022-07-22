# Building a s3gw-ui application image

This documentation will guide you through the several steps to build a
`s3gw-ui` application image.
With `s3gw-ui` image, we are referring at a generic term indicating
an image containing an application used to provide a UI related with the `s3gw`
project.

## Conventions

The `s3gw-ui` application is associated with a `Dockerfile` and adheres to some
conventions:

* Dockerfile build context must be placed inside a directory placed alongside to
  the `s3gw-core` project.
* You should be able to build that application from that directory with:

```text
npm install
npm run build
```

In other words, an `s3gw-ui` application should be consumable by `node` after it
has been built.

## Prerequisites

Make sure you've installed the following applications:

* Podman or Docker

The build script expects the following directory hierarchy.

```text
|
|- s3gw-ui/
|  |- package.json
|  ...
|
|- s3gw-core/
   |- build-ui/
   ...
```

## Build the application

You can build a `s3gw-ui` image by running the `build-ui.sh` script.
The simplest form is:

```shell
$ cd ~/git/s3gw-core/build-ui

$ ./build-ui.sh
Building s3gw-ui image ...
```

Invoking it without any argument, means that the script defaults to the
following environment variables:

```text
IMAGE_NAME        = "s3gw-ui"
CONTAINER_ENGINE  = "podman"
```

## Running the application

You can run a `s3gw-ui` application with:

```shell
$ podman run -p 8080:8080 localhost/s3gw-ui
Starting up http-server, serving dist

http-server version: 14.1.0

...

Available on:
  http://127.0.0.1:8080
  http://<YOUR_HOST_IP>:8080
Hit CTRL-C to stop the server
```
