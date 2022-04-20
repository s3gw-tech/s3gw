# s3gw environment

You can quickly run the `s3gw` container alongside with a Longhorn installation
by following this guide.  
You will get a fully functional Kubernetes cluster installed on top of a set of virtual
machines.  
The entire build process is automated by a set of Ansible playbooks.  
The cluster is created with exactly one `admin` node and 
an arbitrary number of `worker` nodes.  
Name topology for the nodes is the following:

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

You can build the environment with the `s3gwctl.sh` script.  
The simplest form you can use is:  

```bash
$ ./s3gwctl.sh build
Building environment ...
```

This will trigger the build of a Kubernetes cluster formed by one node `admin`
and one node `worker`.  
You can customize the build with the following environment variables:

```text
IMAGE_NAME                  : The Vagrant box image used in the cluster
VM_NET                      : The vm subnet used in the cluster
VM_NET_LAST_OCTET_START     : Vagrant will increment this value when creating vm(s) and assigning an ip
WORKER_COUNT                : The number of Kubernetes workers in the cluster
```

So, you could start a more specialized build with:

```bash
$ IMAGE_NAME=generic/ubuntu1804 WORKER_COUNT=4 ./s3gwctl.sh build
Building environment ...
```

## Destroying the environment

You can destroy a previously built environment with:

```bash
$ ./s3gwctl.sh destroy
Destroying environment ...
```

Be sure to match the `WORKER_COUNT` value with the one you used in the build phase.  
Providing a lower value instead of the actual one will cause some allocated vm not
to be released by Vagrant.

## Accessing the environment

You can connect through `ssh` to all nodes in the cluster.  
To connect to the `admin` node run:

```bash
$ ./s3gwctl.sh ssh admin
Connecting to admin ...
```

To connect to a `worker` node run:

```bash
$ ./s3gwctl.sh ssh worker-2
Connecting to worker-2 ...
```

When connecting to a worker node be sure to match the `WORKER_COUNT` value with the one you used in the build phase.

