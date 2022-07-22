# K8s

Follow this guide if you wish to run an `s3gw` image on the latest stable
Kubernetes release. You will be able to quickly build a cluster installed on a
set of virtual machines. You will have a certain degree of choice in terms of
customization options. If you are looking for a more lightweight environment
running directly on bare metal, refer to our [K3s section](./README.k3s.md).

## Table of Contents

- [Description](#description)
- [Requirements](#requirements)
- [Building the environment](#building-the-environment)
- [Destroying the environment](#destroying-the-environment)
- [Accessing the environment](#accessing-the-environment)
  - [ssh](#ssh)

## Description

The entire environment build process is automated by a set of Ansible playbooks.
The cluster is created with exactly one `admin` node and an arbitrary number of
`worker` nodes. A single virtual machine acting as an `admin` node is also
possible; in this case, it will be able to schedule pods as a `worker` node.
Name topology for nodes is the following:

```text
admin
worker-1
worker-2
...
```

## Requirements

Make sure you have installed the following applications on your system:

- Vagrant
- libvirt
- Ansible

## Building the environment

You can build the environment with the `setup-k8s.sh` script.
The simplest form you can use is:

```bash
$ ./setup-k8s.sh build
Building environment ...
```

This will trigger the build of a Kubernetes cluster formed by one node `admin`
and one node `worker`.

You can customize the build with the following environment variables:

```text
IMAGE_NAME                  : The Vagrant box image used in the cluster
VM_NET                      : The virtual machine subnet used in the cluster
VM_NET_LAST_OCTET_START     : Vagrant will increment this value when creating
                              vm(s) and assigning an ip
CIDR_NET                    : The CIDR subnet used by the Calico network plugin
WORKER_COUNT                : The number of Kubernetes workers in the cluster
ADMIN_MEM                   : The RAM amount used by the admin node (Vagrant
                              format)
ADMIN_CPU                   : The CPU amount used by the admin node (Vagrant
                              format)
ADMIN_DISK                  : yes/no, when yes a disk will be allocated for the
                              admin node - this will be effective only for mono
                              clusters
ADMIN_DISK_SIZE             : The disk size allocated for the admin node
                              (Vagrant format) - this will be effective only for
                              mono clusters
WORKER_MEM                  : The RAM amount used by a worker node (Vagrant
                              format)
WORKER_CPU                  : The CPU amount used by a worker node (Vagrant
                              format)
WORKER_DISK                 : yes/no, when yes a disk will be allocated for the
                              worker node
WORKER_DISK_SIZE            : The disk size allocated for a worker node (Vagrant
                              format)
CONTAINER_ENGINE            : The host's local container engine used to build
                              the s3gw container (podman/docker)
STOP_AFTER_BOOTSTRAP        : yes/no, when yes stop the provisioning just after
                              the bootstrapping phase
START_LOCAL_REGISTRY        : yes/no, when yes start a local insecure image
                              registry at admin.local:5000
S3GW_IMAGE                  : The s3gw's container image used when deploying the
                              application on k8s
K8S_DISTRO                  : The Kubernetes distribution to install; specify
                              k3s or k8s (k8s default)
INGRESS                     : The ingress implementation to be used; NGINX or
                              Traefik (NGINX default)
PROV_USER                   : The provisioning user used by Ansible (vagrant
                              default)
S3GW_UI_REPO                : A GitHub repository to be used when building the
                              s3gw-ui's image
S3GW_UI_VERSION             : A S3GW_UI_REPO's branch to be used
SCENARIO                    : An optional scenario to be loaded in the cluster
```

So, you could start a more specialized build with:

```bash
$ IMAGE_NAME=generic/ubuntu1804 WORKER_COUNT=4 ./setup-k8s.sh build
Building environment ...
```

You create a mono virtual machine cluster with the lone `admin` node with:

```bash
$ WORKER_COUNT=0 ./setup-k8s.sh build
Building environment ...
```

In this case, the node will be able to schedule pods as a `worker` node.

## Destroying the environment

You can destroy a previously built environment with:

```bash
$ ./setup-k8s.sh destroy
Destroying environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build
phase.

Providing a lower value instead of the actual one will cause some allocated vm
not to be released by Vagrant.

## Starting the environment

You can start a previously built environment with:

```bash
$ ./setup-k8s.sh start
Starting environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build
phase.

Providing a lower value instead of the actual one will cause some allocated vm
not to start.

## Accessing the environment

### ssh

You can connect through `ssh` to all nodes in the cluster.

To connect to the `admin` node run:

```bash
$ ./setup-k8s.sh ssh admin
Connecting to admin ...
```

To connect to a `worker` node run:

```bash
$ ./setup-k8s.sh ssh worker-2
Connecting to worker-2 ...
```

When connecting to a worker node be sure to match the `WORKER_COUNT` value with
the one you used in the build phase.
