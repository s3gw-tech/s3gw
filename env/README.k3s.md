# K3s

This README will guide you through the setup of a K3s cluster on your system.  
If you are looking for a vanilla K8s cluster running on virtual machines,
refer to our [K8s section](./README.k8s.md).  
To install K3s on a virtual machine, see [here](#Install-K3s-on-a-virtual-machine).
# Setup

## Note Before

In some host systems, including OpenSUSE Tumbleweed, one will need to disable
firewalld to ensure proper functioning of k3s and its pods:

```
$ sudo systemctl stop firewalld.service
```

This is something we intend figuring out in the near future.

## From the internet

One can easily setup k3s with s3gw from the internet, by running

```
$ curl -sfL https://raw.githubusercontent.com/aquarist-labs/s3gw-core/main/k3s/setup.sh | sh -
```

## From source repository

To install a lightweight Kubernetes cluster for development purpose run
the following commands. It will install open-iscsi and K3s on your local
system. Additionally, it will deploy Longhorn and the s3gw in the cluster.

```
$ cd ~/git/s3gw-core/env
$ ./setup-k3s.sh
```

# Access the Longhorn UI

The Longhorn UI can be access via the URL `http://longhorn.local`.

# Access the S3 API

The S3 API can be accessed via `http://s3gw.local`.

We provide a [s3cmd](https://github.com/s3tools/s3cmd) configuration file
to easily communicate with the S3 gateway in the k3s cluster.

```
$ cd ~/git/s3gw-core/k3s
$ s3cmd -c ./s3cmd.cfg mb s3://foo
$ s3cmd -c ./s3cmd.cfg ls s3://
```

Please adapt the `host_base` and `host_bucket` properties in the `s3cmd.cfg`
configuration file if your K3s cluster is not accessible via localhost.

# Configure s3gw as Longhorn backup target

Use the following values in the Longhorn settings page to use the s3gw as
backup target.

Backup Target: `s3://<BUCKET_NAME>@us/`
Backup Target Credential Secret: `s3gw-secret`

# Install K3s on a virtual machine

## Requirements

Make sure you have installed the following applications on your system:

* Vagrant
* libvirt
* Ansible

In order to install k3s on a virtual machine rather than on bare metal, execute:

```
$ cd ~/git/s3gw-core/env
$ ./setup-k3s.sh --vm
```

Refer to [K8s section](./README.k8s.md) for more configuration options.
