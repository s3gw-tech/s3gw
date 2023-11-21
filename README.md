<h1 align="center"><img alt="s3gw-logo" src="./assets/images/s3gw-logo.png" /></h1>

# s3gw

[![License][license-badge]][license-link]
[![Documentation][docs-badge]][docs-link]
[![Issues][issues-badge]][issues-link]
[![Lint][linter-badge]][linter-link]
[![Release][release-badge]][release-link]
[![Artifact Hub][chart-badge]][chart-link]
[![Slack][slack-badge]][slack-link]

[s3gw][s3gw] is an S3-compatible service focused on deployments in a Kubernetes
environment backed by any PVC, including [Longhorn][longhorn].
Since its inception, the primary focus has been on cloud native deployments.
However, the s3gw can be deployed in a myriad of scenarios, provided some form
of storage is attached.

## Quickstart

<details>
<summary>Helm Chart</summary>
An easy way to deploy the S3 Gateway on your Kubernetes cluster is via a Helm
chart:

```shell
helm repo add s3gw https://aquarist-labs.github.io/s3gw-charts/
helm install s3gw s3gw/s3gw --namespace s3gw-system --create-namespace \
    --set publicDomain=YOUR_DOMAIN_NAME \
    --set ui.publicDomain=YOUR_DOMAIN_NAME
```

Helm is the preferred deployment method, and will automatically use your
cluster's default storage class for the backing store. If you have Longhorn
installed already, s3gw will thus use a Longhorn PV. The above assumes
cert-manager and traefik are available, but these and other settings can
be overridden via values.yaml.

Check out the [documentation][helm-docs] for details and configuration options.
</details>

<details>
<summary>Podman</summary>

```shell
podman run --replace --name=s3gw -it -p 7480:7480 quay.io/s3gw/s3gw:latest
```

Podman deployments will use ephemeral storage inside the container by default,
which should only be used for testing purposes.  To use a directory on the
host system for storage, pass `-v/host-path:/data`.

</details>

<details>
<summary>Docker</summary>

```shell
docker pull quay.io/s3gw/s3gw:latest
```

In order to run the Docker container:

```shell
docker run -p 7480:7480 quay.io/s3gw/s3gw:latest
```

Docker deployments will use ephemeral storage inside the container by default,
which should only be used for testing purposes.  To use a directory on the
host system for storage, pass `-v/host-path:/data`.

</details>

### Docker Compose

**1. Configure the default secrets as environment variables**

```yaml
environment:
  RGW_DEFAULT_USER_ACCESS_KEY: "test"
  RGW_DEFAULT_USER_SECRET_KEY: "test"
```

**2. Run docker-compose**

```bash
docker-compose up -d
```

## Documentation

You can access our documentation [here][docs-link].

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use licensed files except in compliance with the License.
You may obtain a copy of the License at

  <http://www.apache.org/licenses/LICENSE-2.0>

or the LICENSE file in this repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

----

[s3gw]: https://s3gw.io
[longhorn]: https://longhorn.io
[chart-badge]: https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/s3gw
[chart-link]: https://artifacthub.io/packages/search?repo=s3gw
[docs-badge]: https://readthedocs.org/projects/s3gw-docs/badge/?version=latest
[docs-link]: https://s3gw-docs.readthedocs.io/en/latest/?badge=latest
[issues-badge]: https://img.shields.io/github/issues/aquarist-labs/s3gw
[issues-link]: https://github.com/aquarist-labs/s3gw/issues
[license-badge]: https://img.shields.io/github/license/aquarist-labs/s3gw
[license-link]: https://github.com/aquarist-labs/s3gw/blob/main/LICENSE
[linter-badge]: https://github.com/aquarist-labs/s3gw/actions/workflows/lint.yaml/badge.svg
[linter-link]: https://github.com/aquarist-labs/s3gw/actions/workflows/lint.yaml
[release-badge]: https://img.shields.io/github/v/release/aquarist-labs/s3gw
[release-link]: https://github.com/aquarist-labs/s3gw/releases/latest
[slack-badge]: https://img.shields.io/badge/slack-s3gw-brightgreen.svg?logo=slack
[slack-link]: https://slack.com/app_redirect?channel=C04DCMUV8SE
[helm-docs]: https://s3gw-docs.readthedocs.io/en/latest/helm-charts/
