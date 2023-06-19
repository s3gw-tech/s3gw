# Installing s3gw with helm charts

Before you begin, ensure you install helm. To install, see the [documentaiton](https://helm.sh/docs/intro/install/)
or run the following:

```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Clone the s3gw-charts repo and change directory:

```shell
git clone https://aquarist-labs.github.io/s3gw-charts/
cd s3gw-charts
```

## Configuring values.yaml

Helm charts can be customized for your Kubernetes environment. For a
default installation, the only option you are required to update is
the domain and then set the options on the command line directly using
`helm --set key=value`.

**Note:** We do recommend at least updating the default access credenitals,
but it is not necessary for a test installation. See below for more
information.

Once the domain has been configured, the chart can then be installed from
within the repository directory:

```bash
cd s3gw-charts
helm install $RELEASE_NAME charts/s3gw --namespace $S3GW_NAMESPACE \
  --create-namespace -f /path/to/your/custom/values.yaml
```

### Options

#### Access credentials

It is strongly advisable to customize the initial access credentials.
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

#### Service name

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

### Ingress options

The chart can install an ingress resource for a Traefik ingress controller:

```yaml
ingress:
  enabled: true
```

### TLS certificate management

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

**NOTE::** When using self-signed certificates, you may encounter CORS issues
accessing the UI. This can be worked around by first accessing the S3 endpoint
itself `https://hostname` with the browser and accepting that certificate,
before accessing the UI via `https://ui.hostname`

```bash
cat certificate.pem | base64 -w 0
```

#### Storage

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

##### Local storage

You can use the `storageClass.local` and `storageClass.localPath` variables to
set up a node-local volume for testing if you don not have Longhorn. This is an
experimental feature for development use only.

#### Image settings

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

### Other settings

The log verbosity can also be configured for the s3gw pod. Set the `logLevel`
property to a number, with `"0"` being the least verbose and higher numbers
being more verbose:

```yaml
logLevel: "1"
```

#### Container Object Storage Interface (COSI)

> **WARNING**: Be advised that COSI standard is currently in **alpha** state.
> The COSI implementation provided by s3gw is considered an experimental
> feature and changes to the COSI standard are expected in this phase.
> The s3gw team does not control the upstream development of COSI.

##### Prerequisites

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

##### Installation

COSI support is disabled by default in s3gw. To enable it, set:

```yaml
cosi.enabled: true
```

Normally, you don't need to change the chart's defaults for the COSI related fields.

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
