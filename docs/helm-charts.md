# Installation and options

In order to install s3gw using Helm, from this repository directly, first you
must clone the repo:

```bash
  git clone https://github.com/aquarist-labs/s3gw-charts.git
```

Before installing, familiarize yourself with the options, if necessary provide
your own `values.yaml` file.
Then change into the repository and install using helm:

```bash
  cd s3gw-charts
  helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE
  --create-namespace -f /path/to/your/custom/values.yaml
```

## Dependencies

### Traefik

If you intend to install s3gw with an ingress resource, you must ensure your
environment is equipped with a [Traefik](https://helm.traefik.io/traefik)
ingress controller.

## Options

The helm chart can be customized for your Kubernetes environment. To do so,
either provide a `values.yaml` file with your settings, or set the options on
the command line directly using `helm --set key=value`.

### Hostname

Use the `hostname` setting to configure the hostname under which you would like
to make the gateway available:

```yaml
hostname: s3gw.local
```

The plain HTTP endpoint will then be generated as: `no-tls-s3gw.local`

### Ingress Options

The chart can install an ingress resource for a Traefik ingress controller:

```yaml
enableIngress: true
```

### TLS Certificates

provide the TLS certificate in the `values.yaml` file to enable TLS at the
ingress.
Note that the connection between the ingress and s3gw itself within the cluster
will not be TLS protected.

```yaml
tls:
  crt: PUT_YOUR_CERTIFICATE_HERE
  key: PUT_YOUR_CERTIFICATES_KEY_HERE
```

### Existing Volumes

The s3gw is best deployed ontop of a [longhorn](https://longhorn.io) volume. If
you have longhorn installed in your cluster, all appropriate resources will be
automatically deployed for you.
Make sure the `storageType` is set to `"longhorn"` and the correct size for the
claim is set in `storageSize`:

```yaml
storageType: "longhorn"
storageSize: 10Gi
```

However if you want to use s3gw with other storage providers, you can do so too.
You must first deploy a persistent volume claim for your storage provider. Then
you deploy s3gw and set it to use that persistent volume claim (pvc) with:

```yaml
storageType: "pvc"
storage: the-name-of-the-pvc
```

s3gw will then reuse that pvc instead of deploying a longhorn volume.

You can also use local filesystem storage instead, by setting `storageType` to
`"local"`, `storageSize` to the desired quota and `storage` to the path on the
hosts filesystem, e.g:

```yaml
storageType: "local"
storageSize: 10Gi
storage: /mnt/extra-storage/
```

### Image Settings

In some cases, custom image settings are needed, e.g. in an air-gapped
environment, or for developers. In that case, you can modify the registry and
image settings:

```yaml
imageRegistry: "ghcr.io/aquarist-labs"
imageName: "s3gw"
imageTag: "latest"
imagePullPolicy: "Always"
imageRegistry_ui: "ghcr.io/aquarist-labs"
imageName_ui: "s3gw-ui"
imageTag_ui: "latest"
imagePullPolicy_ui: "Always"
```

To configure the image and registry for the user interface, use:

```yaml
imageName_ui: "s3gw-ui"
imageTag_ui: "latest"
```
