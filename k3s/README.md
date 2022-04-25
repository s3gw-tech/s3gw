This README will guide you through the setup of a K3s cluster on your system.

# Setup

To install a lightweight Kubernetes cluster for development purpose run
the following command. It will install open-iscsi and K3s on your local
system. Additionally, it will deploy Longhorn and the s3gw in the cluster.

```
$ cd ~/git/s3gw-core/k3s
$ ./setup.sh
```

# Access the Longhorn UI

The Longhorn UI can be access via the URL `http://localhost:80/longhorn/`.

# Access the S3 API

The S3 API can be accessed via `localhost:80/s3gw`.

We provide a [s3cmd](https://github.com/s3tools/s3cmd) configuration file
to easily communicate with the S3 gateway in the k3s cluster.

```
$ cd ~/git/s3gw-core/k3s
$ s3cmd -c ./s3cmd.cfg mb s3://foo
$ s3cmd -c ./s3cmd.cfg ls s3://
```

Please adapt the `host_base` and `host_bucket` properties in the `s3cmd.cfg`
configuration file if your K3s cluster is not accessible via localhost.
