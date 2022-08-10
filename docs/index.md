# Welcome to the s3gw project

## Project objective

We're building an easy-to-use Open Source and Cloud Native S3 service for
Kubernetes.
Our focus is to complement the Rancher portfolio, although the tool isn't
limited to Rancher products.

## Project priorities

- Complement the Rancher portfolio.
  - S3 solution for: Longhorn volume, Harvester, Epinio backups. Also OPNI models.
  - Leverage k3s/k8s and Longhorn for deployment and redundancy, load balancing,
  etc.
    - Kubernetes-native management (helm chart, GitOps) and an end-user UI for
    operations.
- Single pod deployments (Edge and IoT and smaller on-prem deployments,
development).
  - Not a general-purpose scalable S3 data lake.
  - Scaling would happen via multiple pods serving different instances.
- We're leveraging the feature-rich S3 gateway from Ceph but without the rest of
the Ceph stack (no RADOS).

## Summary

In a nutshell, this project provides the required infrastructure to build a container
able to run on a kubernetes cluster, providing S3-compatible endpoints to
Kubernetes applications.
