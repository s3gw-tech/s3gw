
# Configuring the s3gw

The following configuration options are for the s3gw and can be configured
within the `values.yaml` file.

## Access credentials

We strongly advise customizing the initial access credentials.
These can be used to access the admin UI, as well as the S3 endpoint.
Additional credentials can be created using the admin UI.

Initial credentials for the default user can be provided in different ways:

- **Explicit values**

This is the default mode. You provide explicit values for both the S3 Access
Key and the S3 Secret Key.

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
for the field(s). The generated values are printed to the console
after the installation completes successfully. They can also be
retrieved later.

To obtain the access key:

```bash
kubectl --namespace $S3GW_NAMESPACE get secret \
  $(yq .defaultUserCredentialSecret values.yaml) \
  -o yaml | yq .data.RGW_DEFAULT_USER_ACCESS_KEY | base64 -d
```

To obtain the secret key:

```bash
kubectl --namespace $S3GW_NAMESPACE get secret \
  $(yq .defaultUserCredentialSecret values.yaml) \
  -o yaml | yq .data.RGW_DEFAULT_USER_SECRET_KEY | base64 -d
```

- **Existing secret**

You can provide an existing secret containing the S3 credentials
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

## Ingress options

If you want to expose the S3 service outside the cluster (for example, to a
host static content for a website) you need an ingress for the outside
traffic to reach the s3gw. Set `ingress.enabled` to `true`:

```yaml
ingress:
  enabled: true
```

If you only want cluster-internal access, set to `false`:

```yaml
ingress:
  enabled: false
```

## Certification manager

If you want to have secure connections to the s3gw using TLS and do not want
to manage certificates by hand set `useCertManager` to `true`. This does
require you to have `jetstack certmanager` installed from `https://charts.jetstack.io`.

As `cert-manager` will be installed in its own namespace, you can give a
namespace where the chart can communicate with the cert manager using
`certManagerNamespace`.

## TLS issuer

The `tlsIssuer` property controls how certificates are issued with the `cert-manager`.
Either use `s3gw-letsencrypt-issuer` when you want certificates that are issued by
`letsencrypt` or use the `s3gw-issuer` for a self-signed certificate.

## TLS

If you are not using the cert-manager, you have to manually specify
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

The certificates must be provided as base64 encoded PEM in one long
string without line breaks. You can create them from a PEM file.

## s3gw user interface

`ui.enabled` is by default set to `true`, but can be set to `false` to use
the s3gw standalone.

`ui.serviceName` and `ui.publicDomain` are the hostname and domain name
which the ingress will listed on for access to the UI. If the UI is set
as such:

```yaml
  serviceName: object-browser
  publicDomain: example.com
```

The UI can be accessed under `http(s)://object-browser.example.com`.

## S3 service

`useExistingSecret` can be used to tell the chart that you want to provide a
secret where the access credentials for the first account can be found.
`defaultUserCredentialsSecret` can be used to tell helm which secret that will be.

If `accessKey` and `secretKey` are left empty, credentials will be generated
automatically.

### Service name

There are two possible ways to access the s3gw: from inside the Kubernetes
cluster and from the outside. For both, the s3gw must be configured with the
correct service and domain name. Use the `publicDomain` and the
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

## Storage

The s3gw is best deployed on top of a [Longhorn](https://longhorn.io) volume.
If you have Longhorn installed in your cluster, all appropriate resources are
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

### Local storage

You can use the `storageClass.local` and `storageClass.localPath` variables to
set up a node-local volume for testing if you don not have Longhorn. This is an
experimental feature for development use only.

## Log settings

The log verbosity can also be configured for the s3gw pod. Set the `logLevel`
property to a number, with `"0"` being the least verbose and higher numbers
being more verbose:

```yaml
logLevel: "1"
```

The highest `logLevel` that we recommend is 10, however, any integer required
is valid.

## Developer options

In some cases, custom image settings are needed, for example in an air-gapped
environment or for developers. In that case, you can modify the registry and
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

## Container Object Storage Interface (COSI)

> **WARNING**: Be advised that COSI standard is currently in **alpha** state.
> The COSI implementation provided by s3gw is considered an experimental
> feature and changes to the COSI standard are expected in this phase.
> The s3gw team does not control the upstream development of COSI.

### Prerequisites

If you are going to use COSI, ensure some resources are pre-deployed on the
cluster.

COSI requirements:

- COSI CRDs

To deploy COSI CRDs, run:

```bash
kubectl create -k github.com/kubernetes-sigs/container-object-storage-interface-api
```

- COSI Controller

To deploy the COSI Controller, run:

```bash
kubectl create -k github.com/kubernetes-sigs/container-object-storage-interface-controller
```

Check if the controller pod is in the default namespace:

```shell
NAME                                        READY   STATUS    RESTARTS   AGE
objectstorage-controller-6fc5f89444-4ws72   1/1     Running   0          2d6h
```

### Installation

COSI support is disabled by default in s3gw. To enable it, set:

```yaml
cosi.enabled: true
```

Normally, you do not need to change the chart's defaults for the COSI related fields.

However, the following fields can be customized:

```yaml

cosi.driver.imageName: # It specifies a custom image name for the COSI driver.
                       # Default: s3gw-cosi-driver

cosi.driver.imageTag: # It specifies a custom image tag for the COSI driver.
                      # Default: the current chart version.

cosi.driver.imageRegistry: #It specifies a custom image registry for the COSI driver.
                           #Default: quay.io/s3gw

cosi.driver.imagePullPolicy: # It specifies the pull policy for the COSI driver.
                             # Default: IfNotPresent

cosi.driver.name: # It specifies the name of the COSI driver.
                  # Default: {Release.Name}.{Release.Namespace}.objectstorage.k8s.io

cosi.sidecar.imageName: # It specifies a custom image name for the COSI sidecar.
                        # Default: s3gw-cosi-sidecar

cosi.sidecar.imageTag: # It specifies a custom image tag for the COSI sidecar.
                       # Default: the current chart version.

cosi.sidecar.imageRegistry: # It specifies a custom image registry for the COSI sidecar.
                            # Default: quay.io/s3gw

cosi.sidecar.imagePullPolicy: # It specifies the pull policy for the COSI sidecar.
                              # Default: IfNotPresent

cosi.sidecar.logLevel: # It specifies the log verbosity of the COSI sidecar.
                       # Higher values are more verbose.
                       # Default: 5
```
