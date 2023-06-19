<!-- markdownlint-disable no-duplicate-heading -->
# Installing k8s for s3gw

The following document describes the prerequisite installations to run the
S3 Gateway (s3gw), an S3 object storage service, on top of a vanilla k8s
installation.

## Before you begin

You can install the s3gw for test purposes locally, on baremetal hardware,
or virtually. In each instance, ensure you provide adequate disk space.
Longhorn requires a minimal available storage percentage on the root disk,
which is 25% by default.

## Installing CNI plugin

Kubernetes supports a Container Network Interface (CNI) plugins for cluster
networking and is required to implement the k8s networking model.
See the installation instructions [here](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/).

## Installing ingress controller

If you intend to install s3gw with an ingress resource, ensure your
environment is equipped with a [Traefik](https://helm.traefik.io/traefik)
ingress controller.

You can use a different ingress controller, but note you will have to
create your own ingress resource.

## Installing Longhorn

> **Important:** As part of the Longhorn installation, it is required that
> `open-iscsi` is installed *before* running the Longhorn installation script.
> Ensure this is done so before continuing.

You can install Longhorn either via the `Rancher Apps and Marketplace`,
using `kubectl`, or via a `helm chart`. The instructions can be found
[here](https://longhorn.io/docs/1.4.2/deploy/install/).

To check the progress of the Longhorn installation, run:

```bash
kubectl get pods -w -n longhorn-system
```

### Access the Longhorn UI

Now that you have installed Longhorn, access the localhost UI:
`http://longhorn.<LOCAL-ADDRESS>`.

You should now be able to see Longhorn running and there should be no volumes
present.

## Install certification manager

s3gw uses a [cert-manager](https://cert-manager.io/) in order to create TLS
certificates for the various ingresses and internal ClusterIP resources.

Install `cert-manager` as follows:

```bash
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager --namespace cert-manager jetstack/cert-manager \
    --set installCRDs=true \
    --set extraArgs[0]=--enable-certificate-owner-ref=true
```
