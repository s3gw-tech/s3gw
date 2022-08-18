# Building a s3gw-ui application image

This documentation will guide you through the several steps to build a
`s3gw-ui` application image.
With `s3gw-ui` image, we are referring at a generic term indicating
an image containing an application used to provide a UI related with the `s3gw`
project.

## Conventions

The `s3gw-ui` application is associated with a `Dockerfile` and adheres to some
conventions:

- Dockerfile build context must be placed inside a directory placed alongside to
  the `s3gw-ui` project.
- You should be able to build that application from that directory with:

```text
npm install
npm run build
```

In other words, an `s3gw-ui` application should be consumable by `node` after it
has been built.

## Prerequisites

Make sure you've installed the following applications:

- Podman

The build script expects the following directory hierarchy.

```text
|
|- s3gw-ui/
|  |- package.json
|  ...
|
|- s3gw-tools/
   |- build-ui/
   ...
```

## Build the application

Before building the `s3gw-ui` image you need to build the container
image that is used to compile the Angular based aaplication. To do
so, simply run:

```shell
cd ~/git/s3gw-tools/build-ui
./build.sh builder-image
```

This needs to be done once. After that you can build a `s3gw-ui` image
by running the commands:

```shell
cd ~/git/s3gw-tools/build-ui
./build.sh app
./build.sh app-image
```

## Running the application

You can run a `s3gw-ui` application with:

```shell
podman run --replace --name=s3gw-ui -it -p 8080:8080 localhost/s3gw-ui
```
