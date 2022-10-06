# Quickstart

## Helm chart

Add the helm chart to your helm repos and install from there. There are [several
options][1] for customization.

```shell
helm repo add s3gw https://aquarist-labs.github.io/s3gw-charts/
helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE \
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

[1]: https://github.com/aquarist-labs/s3gw/blob/main/docs/helm-charts.md#options
