# Testing a release

## Context and Problem Statement

Releasing is an essential process for the `s3gw` project. Given the project is
composed by various sub-projects, that need to be prepared, tested, and
eventually released, the Release Process is not trivial.

This document defines and agrees on the steps required to test the `s3gw`
project, and results from splitting the [Release Process ADR][process_adr] in
three documents: [Release Methodology][methodology_adr],
[Release Steps][release_adr] and Release Testing (this document).

This document supersedes the [Release Process ADR][process_adr].

## Note Before

This document requires expansion. The whole team is encouraged to enhance this
document with further testing scenarios.

## Validate deployment via Helm Chart

1. Ensure a Kubernetes distribution with Longhorn and cert-manager installed is available. E.g.,
   for `k3s`,

   ```shell
   curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.7+k3s1 sh -s - --write-kubeconfig-mode 644
   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   sudo chown my-user:users ~/.kube/config
   export KUBECONFIG=~/.kube/config

   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.2/deploy/prerequisite/longhorn-iscsi-installation.yaml
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.2/deploy/longhorn.yaml

   kubectl create namespace cert-manager
   helm repo add jetstack https://charts.jetstack.io
   helm repo update
   helm install cert-manager --namespace cert-manager jetstack/cert-manager \
        --set installCRDs=true \
        --set extraArgs[0]=--enable-certificate-owner-ref=true
   ```

2. Follow the Helm chart installation procedure from the `s3gw`
   [documentation][helm_install_docs]

3. Verify the pods are coming up nicely

   ```shell
   kubectl get pods -n s3gw

   > NAME                       READY   STATUS    RESTARTS   AGE
   > s3gw-ui-77b7cdf987-c5lvj   1/1     Running   0          33s
   > s3gw-5659dbb456-a4fcg      1/1     Running   0          33s
   ```

4. Check whether the `s3gw-ui` is reachable at the address specified in the
   `values.yaml` provided during `helm install`.

5. Check whether the you can perform actions through the UI, like creating
   buckets, uploading objects, listing buckets, etc.

6. Check whether the `s3gw` service is reachable, test with `s3cmd` or `s3`.

7. If at any point there's an indication that something is not working right, or
   you find a crash, please file an [issue on GitHub][new_issue].

[process_adr]: ./0007-release-process.md
[methodology_adr]: ./0015-release-methodology.md
[release_adr]: ./0016-release-steps.md
[helm_install_docs]: https://s3gw-docs.readthedocs.io/en/latest/helm-charts/
[new_issue]: https://github.com/aquarist-labs/s3gw/issues/new/choose
