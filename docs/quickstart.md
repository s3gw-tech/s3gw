# Quickstart

## Rancher

You can install the s3gw via the Rancher App Catalog. The steps are as follows:

- Cluster -> Projects/Namespaces - create the `s3gw` namespace.
- Apps -> Repositories -> Create `s3gw` using the s3gw-charts Web URL
  <https://aquarist-labs.github.io/s3gw-charts/> and the main branch.
- Apps -> Charts -> Install Traefik.
- Apps -> Charts -> Install `s3gw`.
  Select the `s3gw` namespace previously created.

## Helm chart

Add the helm chart to your helm repos and install from there. There are [several
options][1] for customization.

```bash
helm repo add s3gw https://aquarist-labs.github.io/s3gw-charts/
helm install $RELEASE_NAME s3gw/s3gw --namespace $S3GW_NAMESPACE \
  --create-namespace -f /path/to/your/custom/values.yaml
```

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
[guide](../developing/#how-to-build-your-own-containers/).

[1]: https://github.com/aquarist-labs/s3gw/blob/main/docs/helm-charts.md#options
