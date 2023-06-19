# Installing s3gw with Helm charts

Before you begin, ensure you install Helm. To install, see the [documentation](https://helm.sh/docs/intro/install/)
or run the following:

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Clone the s3gw-charts repo and change directory:

```bash
git clone https://aquarist-labs.github.io/s3gw-charts/
cd s3gw-charts
```

## Configuring values.yaml

Helm charts can be customized for your Kubernetes environment. For a
default installation, the only option you are required to update is
the domain and then set the options on the command line directly using
`helm --set key=value`.

> **Note:** We do recommend at least updating the default access credentials,
> but it is not necessary for a test installation. See the [options](#options)
> section for more details.

Once the domain has been configured, the chart can then be installed from
within the repository directory:

```bash
cd s3gw-charts
helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE \
    --create-namespace -f /path/to/your/custom/values.yaml
```

For details on the various s3gw releases and names, see the release section on
[GitHub](https://github.com/aquarist-labs/s3gw/releases).
