# K3s & K8s environment to run s3gw with Longhorn

This is the entrypoint to setup a Kubernetes cluster on your system.  
You can either choose to install a lightweight **K3s** cluster or a **vanilla K8s** 
cluster running the latest stable Kubernetes version available.  
Regardless of the choice, you will get a provisioned cluster set up to work with
`s3gw` and Longhorn.  
K3s version will install directly on your host.  
K8s version will install on an arbitrary number of virtual machines depending on the
size of the cluster.

Refer to the appropriate sections to proceed with the setup of the environment:  

* [K3s Setup](./README.k3s.md)
* [K8s Setup](./README.k8s.md)
