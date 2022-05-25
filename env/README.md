# K3s & K8s environment running s3gw with Longhorn

This is the entrypoint to setup a Kubernetes cluster on your system.  
You can either choose to install a lightweight **K3s** cluster or a **vanilla K8s**
cluster running the latest stable Kubernetes version available.  
Regardless of the choice, you will get a provisioned cluster set up to work with
`s3gw` and Longhorn.  
K3s version can install directly on bare metal or on virtual machine.  
K8s version will install on an arbitrary number of virtual machines depending on the
size of the cluster.

Refer to the appropriate section to proceed with the setup of the environment:  

* [K3s Setup](./README.k3s.md)
* [K8s Setup](./README.k8s.md)

## Ingresses

Services are exposed with an Kubernetes ingress; each service category is
allocated on a separate virtual host:

* **Longhorn dashboard**, on: `longhorn.local`
* **s3gw**, on: `s3gw.local` and `s3gw-no-tls.local`

Host names are exposed with a node port service listening on ports
30443 (https) and 30080 (http).  
You are required to resolve these names with the external ip of one
of the nodes of the cluster.  

When you are running the cluster on a virtual machine,
you can patch host's `/etc/hosts` file as follow:  

```text
10.46.201.101   longhorn.local s3gw.local s3gw-no-tls.local
```

This makes host names resolving with the admin node.  
Otherwise, when you are running the cluster on bare metal,
you can patch host's `/etc/hosts` file as follow:  

```text
127.0.0.1   longhorn.local s3gw.local s3gw-no-tls.local
```

Services can now be accessed at:

```text
https://longhorn.local:30443
https://s3gw.local:30443
http://s3gw-no-tls.local:30080
```
