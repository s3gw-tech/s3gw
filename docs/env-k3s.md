# K3s environment running s3gw with Longhorn

This is the entrypoint to setup a Kubernetes cluster running s3gw with Longhorn.
You can choose to install a **K3s** cluster directly on your machine
or on top of virtual machines.

Refer to the appropriate section to proceed with the setup:

- [K3s on bare metal](#k3s-on-bare-metal)
- [K3s on virtual machines](#k3s-on-virtual-machines)

## Ingresses

Services are exposed with an Kubernetes ingress; each service category is
allocated on a separate virtual host:

- **Longhorn dashboard**, on: `longhorn.local`
- **s3gw**, on: `s3gw.local` and `s3gw-no-tls.local`
- **s3gw s3 explorer**, on: `s3gw-ui.local` and `s3gw-ui-no-tls.local`

Host names are exposed with a node port service listening on ports
30443 (https) and 30080 (http).
You are required to resolve these names with the external ip of one
of the nodes of the cluster.

When you are running the cluster on a virtual machine,
you can patch host's `/etc/hosts` file as follow:

```text
10.46.201.101   longhorn.local s3gw.local s3gw-no-tls.local s3gw-ui.local s3gw-ui-no-tls.local
```

This makes host names resolving with the admin node.
Otherwise, when you are running the cluster on bare metal,
you can patch host's `/etc/hosts` file as follow:

```text
127.0.0.1   longhorn.local s3gw.local s3gw-no-tls.local s3gw-ui.local s3gw-ui-no-tls.local
```

Services can now be accessed at:

```text
https://longhorn.local:30443
https://s3gw.local:30443
http://s3gw-no-tls.local:30080
https://s3gw-ui.local:30443
http://s3gw-ui-no-tls.local:30080
```

## K3s on Bare Metal

This README will guide you through the setup of a K3s cluster on bare metal.
If you are looking for K3s cluster running on virtual machines,
refer to our [K3s on virtual machines](./README.vm.md).

### Disabling firewalld

In some host systems, including OpenSUSE Tumbleweed, one will need to disable
firewalld to ensure proper functioning of k3s and its pods:

```shell
sudo systemctl stop firewalld.service
```

This is something we intend figuring out in the near future.

### From the internet

One can easily setup k3s with s3gw from the internet, by running

```shell
curl -sfL \
  https://raw.githubusercontent.com/aquarist-labs/s3gw-core/main/k3s/setup.sh \
  | sh -
```

### From source repository

To install a lightweight Kubernetes cluster for development purpose run
the following commands. It will install open-iscsi and K3s on your local
system. Additionally, it will deploy Longhorn and the s3gw in the cluster.

```shell
cd ~/git/s3gw-core/env
./setup.sh
```

### Access the Longhorn UI

The Longhorn UI can be access via the URL `http://longhorn.local`.

### Access the S3 API

The S3 API can be accessed via `http://s3gw.local`.

We provide a [s3cmd](https://github.com/s3tools/s3cmd) configuration file
to easily communicate with the S3 gateway in the k3s cluster.

```shell
cd ~/git/s3gw-core/k3s
s3cmd -c ./s3cmd.cfg mb s3://foo
s3cmd -c ./s3cmd.cfg ls s3://
```

Please adapt the `host_base` and `host_bucket` properties in the `s3cmd.cfg`
configuration file if your K3s cluster is not accessible via localhost.

### Configure s3gw as Longhorn backup target

Use the following values in the Longhorn settings page to use the s3gw as
backup target.

Backup Target: `s3://<BUCKET_NAME>@us/`
Backup Target Credential Secret: `s3gw-secret`

## K3s on Virtual Machines

Follow this guide if you wish to run a K3s cluster installed on virtual
machines. You will have a certain degree of choice in terms of customization
options. If you are looking for a more lightweight environment running directly
on bare metal, refer to our [K3s on bare metal](./README.bm.md).

### Table of Contents

- [Description](#description)
- [Requirements](#requirements)
- [Supported Vagrant boxes](#supported-vagrant-boxes)
- [Building the environment](#building-the-environment)
- [Destroying the environment](#destroying-the-environment)
- [Accessing the environment](#accessing-the-environment)
  - [ssh](#ssh)

### Description

The entire environment build process is automated by a set of Ansible playbooks.
The cluster is created with one `admin` node and an arbitrary number of `worker`
nodes. A single virtual machine acting as an `admin` node is also possible; in
this case, it will be able to schedule pods as a `worker` node. Name topology of
nodes is the following:

```text
admin-1
worker-1
worker-2
...
```

### Requirements

Make sure you have installed the following applications on your system:

- Vagrant
- libvirt
- Ansible

Make sure you have installed the following Ansible modules:

- kubernetes.core
- community.docker.docker_image

You can install them with:

```bash
$ ansible-galaxy collection install kubernetes.core
...
$ ansible-galaxy collection install community.docker
...
```

### Supported Vagrant boxes

- opensuse/Leap-15.3.x86_64
- generic/ubuntu[1604-2004]

### Building the environment

You can build the environment with the `setup-vm.sh` script.
The simplest form you can use is:

```bash
$ ./setup-vm.sh build
Building environment ...
```

This will trigger the build of a Kubernetes cluster formed by one node `admin`
and one node `worker`.
You can customize the build with the following environment variables:

```text
BOX_NAME                    : The Vagrant box image used in the cluster
                              (default: opensuse/Leap-15.3.x86_64)
VM_NET                      : The virtual machine subnet used in the cluster
VM_NET_LAST_OCTET_START     : Vagrant will increment this value when creating
                              vm(s) and assigning an ip
WORKER_COUNT                : The number of Kubernetes node in the cluster
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
S3GW_IMAGE                  : The s3gw's container image used when deploying the
                              application on k3s
PROV_USER                   : The provisioning user used by Ansible (vagrant
                              default)
S3GW_UI_REPO                : A GitHub repository to be used when building the
                              s3gw-ui's image
S3GW_UI_VERSION             : A S3GW_UI_REPO's branch to be used
SCENARIO                    : An optional scenario to be loaded in the cluster
K3S_VERSION                 : The K3s version to be used (default: v1.23.6+k3s1)
```

So, you could start a more specialized build with:

```bash
$ BOX_NAME=generic/ubuntu1804 WORKER_COUNT=4 ./setup-vm.sh build
Building environment ...
```

You create a mono virtual machine cluster with the lone `admin` node with:

```bash
$ WORKER_COUNT=0 ./setup-vm.sh build
Building environment ...
```

In this case, the node will be able to schedule pods as a `worker` node.

### Destroying the environment

You can destroy a previously built environment with:

```bash
$ ./setup-vm.sh destroy
Destroying environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build
phase. Providing a lower value instead of the actual one will cause some
allocated vm not to be released by Vagrant.

### Starting the environment

You can start a previously built environment with:

```bash
$ ./setup-vm.sh start
Starting environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build
phase. Providing a lower value instead of the actual one will cause some
allocated vm not to start.

### Accessing the environment

You can connect through `ssh` to all nodes in the cluster.
To connect to the `admin` node run:

```bash
$ ./setup-vm.sh ssh admin
Connecting to admin ...
```

To connect to a `worker` node run:

```bash
$ ./setup-vm.sh ssh worker-2
Connecting to worker-2 ...
```

When connecting to a worker node be sure to match the `WORKER_COUNT`
value with the one you used in the build phase.
