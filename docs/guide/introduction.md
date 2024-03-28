---
slug: /
---

# Welcome to the s3gw project

## What are we doing?

The s3gw project helps Kubernetes users who need object storage (S3) to back up
their application data to a ([Longhorn][5]) PV by offering a lightweight, Open Source
S3 service, which is easy to deploy in a Cloud Native world.

## Why are we doing it?

We have identified a need for making cluster data backups easily available for
apps that do not require petabyte-scale storage.

## Features

- An intuitive UI
- S3 API compatibility
- Kubernetes-native management
- Leverages the feature-rich S3 gateway from Ceph
- Strong integration with the Rancher Portfolio

## Use cases

- Epinio: Backups/CRDs
- Harvester: Backups
- OPNI: Backups
- K3S/Edge
- SAP Data Intelligence

## Value proposition

- Ideal for small-scale deployments/Edge
- Lightweight, simple User Experience
- Simple: Storage/replication handled by a PV ([Longhorn][5])
- Designed to integrate with Rancher's product catalog
- Open source licensing (Apache 2.0)

## About the project

The s3gw project is split into 4 work streams: [rgw/sfs-ceph][1] (backend),
[s3gw][2] (tooling), [s3gw-charts][3] (helm charts) and [s3gw-ui][4]
(frontend).

[1]: https://github.com/s3gw-tech/s3gw-ceph
[2]: https://github.com/s3gw-tech/s3gw
[3]: https://github.com/s3gw-tech/s3gw-charts
[4]: https://github.com/s3gw-tech/s3gw-ui
[5]: https://longhorn.io/
