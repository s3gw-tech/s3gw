# Quickstart

## Helm chart

Assuming you've cloned the repo as instructed [here](helm-charts.md):

```shell
  cd s3gw-charts
  helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE
  --create-namespace -f /path/to/your/custom/values.yaml
```

## Podman

```shell
podman run --replace --name=s3gw -it -p 7480:7480 ghcr.io/aquarist-labs/s3gw:latest
```

## Docker

```shell
docker pull ghcr.io/aquarist-labs/s3gw:latest
```

In order to run the Docker container:

```shell
docker run -p 7480:7480 ghcr.io/aquarist-labs/s3gw:latest
```

For more information on building and running a container, please read our
[guide](../developing/#how-to-build-your-own-containers/).
