<!-- markdownlint-disable no-duplicate-heading -->
# Installing k8s for s3gw

The following document describes the prerequisite installations to run the
S3 Gateway (s3gw): an S3 object storage service.

To install the s3gw, a Kubernetes (k8s) distribution is required.
This project recommends utilizing k3s as a minimal k8s distribution but
any k8s distribution can be used.

For the purpose of this document, k3s is the chosen k8s distribution and will
be referenced continuously throughout this document.

## Prerequisites

If using openSUSE Tumbleweed, we recommend stopping
firewalld to ensure k3s runs with full functionality. To do so, run:

```shell
systemctl stop firewalld.service
```

You can install the s3gw for test purposes locally, on baremetal hardware,
or virtually. In each instance, ensure you provide adequate disk space.
Longhorn requires a minimal available storage percentage on the root disk,
which is 25% by default.

### Traefik

If you intend to install s3gw with an ingress resource, you must ensure your
environment is equipped with a [Traefik](https://helm.traefik.io/traefik)
ingress controller.

You can use a different ingress controller, but note you will have to
create your own ingress resource.

## Installing k3s

Before you begin, ensure you install k3s. You can find the installation
instructions [here](https://k3s.io/) or, run:
`curl -sfL https://get.k3s.io | sh -`.

Ensure you move the k3s.yaml file, usually hosted in
`/etc/rancher/k3s/k3s.yaml`, to `~/.kube/config` to access the
certificates.

## Installing Longhorn

**Important:** As part of the Longhorn installation, it is required that
`open-iscsi` is installed *before* running the Longhorn installation script.
Ensure this is done so before continuing.

You can install Longhorn either via the `Rancher Apps and Marketplace`,
using `kubectl`, or via a `helm chart`. The instructions can be found
[here](https://longhorn.io/docs/1.4.2/deploy/install/).

To check the progress of the Longhorn installation, run:

```shell
kubectl get pods -w -n longhorn-system
```

### Access the Longhorn UI

Now that you have installed Longhorn, access the localhost UI:
`http://longhorn.<LOCAL-ADDRESS>`.

You should now be able to see Longhorn running and there are no volumes.

## Install certification manager

s3gw uses a [cert-manager](https://cert-manager.io/) in order to create TLS
certificates for the various ingresses and internal ClusterIP resources.

Install `cert-manager` as follows:

```shell
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager --namespace cert-manager jetstack/cert-manager \
    --set installCRDs=true \
    --set extraArgs[0]=--enable-certificate-owner-ref=true
```
