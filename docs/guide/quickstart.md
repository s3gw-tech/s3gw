# Quickstart

## Rancher

You can install the s3gw via the Rancher App Catalog. The steps are as follows:

- Cluster -> Projects/Namespaces - create the `s3gw` namespace.
- Apps -> Repositories -> Create `s3gw` using the s3gw-charts Web URL
  [https://s3gw-tech.github.io/s3gw-charts/](https://s3gw-tech.github.io/s3gw-charts/)
  and the main branch.
- Apps -> Charts -> Install Traefik.
- Apps -> Charts -> Install `s3gw`.
  Select the `s3gw` namespace previously created.

## Podman

```shell
podman run --replace --name=s3gw -it -p 7480:7480 quay.io/s3gw/s3gw:latest
```

## Docker

```shell
docker pull quay.io/s3gw/s3gw:latest
```

In order to run the Docker container:

```shell
docker run -p 7480:7480 quay.io/s3gw/s3gw:latest
```

For more information on building and running a container, read our
[guide](./developing#how-to-build-your-own-containers).
