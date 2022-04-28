# s3gw environment

You can quickly run the `s3gw` container alongside with a Longhorn installation
by following this guide.  
You will get a fully functional Kubernetes cluster installed on top of a set of virtual
machines.  
If you are looking for a more lightweight environment, please refer to our [K3s section](../k3s/README.md).

## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Building the environment](#building-the-environment)
* [Destroying the environment](#destroying-the-environment)
* [Accessing the environment](#accessing-the-environment)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

## Description

The entire environment build process is automated by a set of Ansible playbooks.  
The cluster is created with exactly one `admin` node and
an arbitrary number of `worker` nodes.  
A single virtual machine acting as an `admin` node is also possible; in this case, it
will be able to schedule pods as a `worker` node.  
Name topology for nodes is the following:

```text
admin
worker-1
worker-2
...
```

## Requirements

Make sure you have installed the following applications on your system:

* Vagrant
* libvirt
* Ansible

## Building the environment

You can build the environment with the `s3gwctl` script.  
The simplest form you can use is:  

```bash
$ ./s3gwctl build
Building environment ...
```

This will trigger the build of a Kubernetes cluster formed by one node `admin`
and one node `worker`.  
You can customize the build with the following environment variables:

```text
IMAGE_NAME                  : The Vagrant box image used in the cluster
VM_NET                      : The virtual machine subnet used in the cluster
VM_NET_LAST_OCTET_START     : Vagrant will increment this value when creating vm(s) and assigning an ip
CIDR_NET                    : The CIDR subnet used by the Calico network plugin
WORKER_COUNT                : The number of Kubernetes workers in the cluster
ADMIN_MEM                   : The RAM amount used by the admin node (Vagrant format)
ADMIN_CPU                   : The CPU amount used by the admin node (Vagrant format)
ADMIN_DISK_SIZE             : The disk size allocated for the admin node (Vagrant format) - this will be effective only for mono clusters
WORKER_MEM                  : The RAM amount used by a worker node (Vagrant format)
WORKER_CPU                  : The CPU amount used by a worker node (Vagrant format)
WORKER_DISK_SIZE            : The disk size allocated for a worker node (Vagrant format)
LOCAL_CNT_ENG               : The host's local container engine used to build the s3gw container (podman/docker)
```

So, you could start a more specialized build with:

```bash
$ IMAGE_NAME=generic/ubuntu1804 WORKER_COUNT=4 ./s3gwctl build
Building environment ...
```

You create a mono virtual machine cluster with the lone `admin` node with:

```bash
$ WORKER_COUNT=0 ./s3gwctl build
Building environment ...
```

In this case, the node will be able to schedule pods as a `worker` node.  

## Destroying the environment

You can destroy a previously built environment with:

```bash
$ ./s3gwctl destroy
Destroying environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build phase.  
Providing a lower value instead of the actual one will cause some allocated vm not
to be released by Vagrant.

## Accessing the environment

You can connect through `ssh` to all nodes in the cluster.  
To connect to the `admin` node run:

```bash
$ ./s3gwctl ssh admin
Connecting to admin ...
```

To connect to a `worker` node run:

```bash
$ ./s3gwctl ssh worker-2
Connecting to worker-2 ...
```

When connecting to a worker node be sure to match the `WORKER_COUNT` value with the one you used in the build phase.
