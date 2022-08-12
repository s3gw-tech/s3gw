# s3gw

![License](https://img.shields.io/github/license/aquarist-labs/s3gw)
![Issues](https://img.shields.io/github/issues/aquarist-labs/s3gw)
![Lint](https://github.com/aquarist-labs/s3gw/actions/workflows/lint.yaml/badge.svg)
![Build](https://github.com/aquarist-labs/s3gw/actions/workflows/build-environment.yml/badge.svg)

We're developing an easy-to-use Open Source and Cloud Native S3 service for
Kubernetes.

## Quickstart

### Helm chart

An easy way to deploy the S3 Gateway on your Kubernetes cluster is via a Helm
chart. We've created a dedicated repository for it, which can be found
[here][1].

### Podman

```shell
podman run --replace --name=s3gw -it -p 7480:7480 ghcr.io/aquarist-labs/s3gw:latest
```

### Docker

```shell
docker pull ghcr.io/aquarist-labs/s3gw:latest
```

In order to run the Docker container:

```shell
docker run -p 7480:7480 ghcr.io/aquarist-labs/s3gw:latest
```

For more information on building and running a container, please read our
[guide](./build/).

## Documentation

You can access our documentation [here][2].

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

=======

[1]: https://github.com/aquarist-labs/s3gw-charts
[2]: https://s3gw-docs.readthedocs.io/en/latest/
