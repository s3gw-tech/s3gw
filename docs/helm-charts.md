# Installation and options

The canonical way to install the helm chart is via a helm repository:

```bash
helm repo add s3gw https://aquarist-labs.github.io/s3gw-charts/
helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE \
  --create-namespace -f /path/to/your/custom/values.yaml
```

The chart can also be installed directly from the git repository. To do so, the
repo must be cloned first:

```bash
git clone https://github.com/aquarist-labs/s3gw-charts.git
```

And then the chart can be installed from within the repo directory:

```bash
cd s3gw-charts
helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE \
  --create-namespace -f /path/to/your/custom/values.yaml
```

Before installing, familiarize yourself with the options, if necessary provide
your own `values.yaml` file.

## Rancher

Installing s3gw via the Rancher App Catalog is made easy, the steps are as
follow

- Cluster -> Projects/Namespaces - create the `s3gw` namespace.
- Storage -> PersistentVolumeClaim -> Create -> choose the `s3gw` namespace ->
  provide a size and name it `s3gw-pvc`.
- Apps -> Repositories -> Create `s3gw` using the s3gw-charts Git URL
  <https://github.com/aquarist-labs/s3gw-charts> and the main branch.
- Apps -> Charts -> Install Traefik.
- Apps -> Charts -> Install `s3gw` -> Storage -> Storage Type: `pvc` -> PVC
  Name: `s3gw-pvc`.

## Dependencies

### Traefik

If you intend to install s3gw with an ingress resource, you must ensure your
environment is equipped with a [Traefik](https://helm.traefik.io/traefik)
ingress controller.

## Options

The helm chart can be customized for your Kubernetes environment. To do so,
either provide a `values.yaml` file with your settings, or set the options on
the command line directly using `helm --set key=value`.

### Access Credentials

It is strongly advisable to customize the initial access credentials.
These can be used to access the admin UI, as well as the S3 endpoint. Additional
credentials can be created using the admin UI.

```yaml
accessKey: admin
secretKey: foobar
```

### Hostname

Use the `hostname`, `hostnameNoTLS`, `ui.hostname` and `ui.hostnameNoTLS`
settings to configure the hostname under which you would like
to make the gateway and it's user interface available:

```yaml
hostname: s3gw.local
```

### Ingress Options

The chart can install an ingress resource for a Traefik ingress controller:

```yaml
ingress:
  enabledtrue
```

### TLS Certificates

provide the TLS certificate in the `values.yaml` file to enable TLS at the
ingress. Note that the connection between the ingress and s3gw itself within the
cluster will not be TLS protected.

```yaml
ui:
  tls:
    crt: CERTIFICATE_FOR_UI
    key: CERTIFICATE_KEY_FOR_UI
tls:
  crt: PUT_YOUR_CERTIFICATE_HERE
  key: PUT_YOUR_CERTIFICATES_KEY_HERE
```

Note that the certificates must be provided as base64 encoded PEM in one long
string without line breaks. You can create them from a PEM file:

When using self-signed certificates, you may encounter CORS issues accessing the
UI. This can be worked around by first accessing the S3 endpoint itself
`https://hostname` with the browser and accepting that certificate, before
accessing the UI via `https://ui.hostname`

```bash
cat certificate.pem | base64 -w 0
```

### Storage

The s3gw is best deployed on top of a [longhorn](https://longhorn.io) volume. If
you have longhorn installed in your cluster, all appropriate resources will be
automatically deployed for you.

The size of the volume can be controlled with `storageSize`:

```yaml
storageSize: 10Gi
```

If you want to reuse an existing storage class or otherwise need more control
over storage settings, set `storageClass.create` to `false` and
`storageClass.name` to the name of your preferred storage class.

```yaml
storageClass:
  name: my-custom-storageclass
  create: false
```

#### Local Storage

You can use the `storageClass.local` and `storageClass.localPath` variables to
set up a node-local volume for testing, if you don't have longhorn. This is an
experimental feature for development use only.

### Image Settings

In some cases, custom image settings are needed, e.g. in an air-gapped
environment, or for developers. In that case, you can modify the registry and
image settings:

```yaml
imageRegistry: "ghcr.io/aquarist-labs"
imageName: "s3gw"
imageTag: "latest"
imagePullPolicy: "Always"
```

To configure the image and registry for the user interface, use:

```yaml
ui.imageRegistry: "ghc.io/aquarist-labs"
ui.imageName: "s3gw-ui"
ui.imagePullPolicy: "Always"
ui.imageTag: "latest"
```
