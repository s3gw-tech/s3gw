# Installation and options

The canonical way to install the helm chart is via a helm repository:

```bash
helm repo add s3gw https://aquarist-labs.github.io/s3gw-charts/
helm install $RELEASE_NAME s3gw/s3gw --namespace $S3GW_NAMESPACE \
  --create-namespace -f /path/to/your/custom/values.yaml
```

The chart can also be installed directly from the git repository. To do so, the
repository must be cloned first:

```bash
git clone https://github.com/aquarist-labs/s3gw-charts.git
```

And then the chart can be installed from within the repository directory:

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
- Apps -> Repositories -> Create `s3gw` using the s3gw-charts Web URL
  <https://aquarist-labs.github.io/s3gw-charts/> and the main branch.
- Apps -> Charts -> Install Traefik.
- Apps -> Charts -> Install `s3gw`.
  Select the `s3gw` namespace previously created.

## Dependencies

### Traefik

If you intend to install s3gw with an ingress resource, you must ensure your
environment is equipped with a [Traefik](https://helm.traefik.io/traefik)
ingress controller.

You may also use a different ingress controller, but then you will have to
create your own ingress resource.

### Cert Manager

If you wish, you can automate the TLS certificate management.
s3gw can use [cert-manager](https://cert-manager.io/) in order to create TLS
certificates for the various Ingresses and internal ClusterIP resources.

If cert-manager is not already installed on the cluster,
it can be installed like this:

```shell
$ kubectl create namespace cert-manager
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ helm install cert-manager --namespace cert-manager jetstack/cert-manager \
    --set installCRDs=true \
    --set extraArgs[0]=--enable-certificate-owner-ref=true
```

> **WARNING**: if cert-manager isn't installed in the namespace `cert-manager`,
> you have to set `.Values.certManagerNamespace` accordingly,
otherwise s3gw installation will fail.

## Options

The helm chart can be customized for your Kubernetes environment. To do so,
either provide a `values.yaml` file with your settings, or set the options on
the command line directly using `helm --set key=value`.

### Access Credentials

It is strongly advisable to customize the initial access credentials.
These can be used to access the admin UI, as well as the S3 endpoint. Additional
credentials can be created using the admin UI.

Initial credentials for the default user can be provided in different ways:

- **Explicit values**

This is the default mode. You provide explicit values for both the S3 Access Key
and the S3 Secret Key.

```yaml
accessKey: admin
secretKey: foobar
```

- **Random values**

If you set `accessKey` and/or `secretKey` as the empty string:

```yaml
accessKey:
secretKey:
```

The chart then computes a random alphanumeric string of 32 characters
for the field(s).

- **Existing secret**

You provide an existing secret containing the S3 credentials
for the default user. This secret must contain 2 keys:

- `RGW_DEFAULT_USER_ACCESS_KEY`: the S3 Access Key for the default user.
- `RGW_DEFAULT_USER_SECRET_KEY`: the S3 Secret Key for the default user.

To use this configuration, you have to enable the flag:

```yaml
useExistingSecret: true
```

You can set the name of the existing secret with:

```yaml
defaultUserCredentialsSecret: "my-secret"
```

### Service name

There are two possible ways to access the s3gw: from inside the Kubernetes
cluster and from the outside. For both, the s3gw must be configured with the
correct service and domain name. Use the `publicDomtain` and the
`ui.publicDomain` setting to configure the domain under which the s3gw and the
UI respectively be available to the outside of the Kubernetes cluster. Use the
`privateDomain` setting to set the cluster's internal domain and make the s3gw
available inside the cluster to other deployments.

```yaml
serviceName: s3gw
publicDomain: "fe.127.0.0.1.omg.howdoi.website"
privateDomain: "s3gw-namespace.svc.cluster.local"
ui:
  serviceName: s3gw-ui
  publicDomain: "be.127.0.0.1.omg.howdoi.website"
```

### Ingress Options

The chart can install an ingress resource for a Traefik ingress controller:

```yaml
ingress:
  enabled: true
```

### TLS Certificate Management

When not using cert-manager, you have to manually specify
the TLS certificates in the `values.yaml` file to enable TLS
at the various Ingresses and ClusterIP resources.
Note that the connection between the Ingress and the s3gw's ClusterIP
within the cluster will not be TLS protected.

```yaml
tls:
  publicDomain:
    crt: PUBLIC_DOMAIN_CERTIFICATE_HERE
    key: PUBLIC_DOMAIN_CERTIFICATE_KEY_HERE
  privateDomain:
    crt: PRIVATE_DOMAIN_CERTIFICATE_HERE
    key: PRIVATE_DOMAIN_CERTIFICATE_KEY_HERE
  ui:
    publicDomain:
      crt: CERTIFICATE_FOR_UI
      key: CERTIFICATE_KEY_FOR_UI
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

### Other Settings

The log verbosity can also be configured for the s3gw pod. Set the `logLevel`
property to a number, with `"0"` being the least verbose and higher numbers
being more verbose:

```yaml
logLevel: "1"
```
