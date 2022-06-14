# K3s environment running s3gw with Longhorn

This is the entrypoint to setup a Kubernetes cluster running s3gw with Longhorn.  
You can choose to install a **K3s** cluster directly on your machine
or on top of virtual machines.  

Refer to the appropriate section to proceed with the setup:  

* [K3s on bare metal](./README.bm.md)
* [K3s on virtual machines](./README.vm.md)

## Ingresses

Services are exposed with an Kubernetes ingress; each service category is
allocated on a separate virtual host:

* **Longhorn dashboard**, on: `longhorn.local`
* **s3gw**, on: `s3gw.local` and `s3gw-no-tls.local`
* **s3gw s3 explorer**, on: `s3gw-ui.local` and `s3gw-ui-no-tls.local`

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
