# Release Notes - v0.9.0

This release introduces some notable changes to Charts,
together with UI improvements.
As usual, we are improving the overall quality of the project by
addressing issues to documentation, testing, UI and tools.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- Charts
  - Add configuration options: `serviceName`, `publicDomain`, `privateDomain`
    to configure the s3gw-service's public domain used by the Ingress
    and the private domain used inside the Kubernetes cluster.
  - Defaulted values:
    - `serviceName` : s3gw
    - `publicDomain` : be.127.0.0.1.omg.howdoi.website
    - `privateDomain` : svc.cluster.local
  - Add configuration options: `ui.serviceName`, `ui.publicDomain`
    to configure the s3gw-ui-service's public domain used by
    the Ingress.
  - Defaulted values:
    - `ui.serviceName` : s3gw-ui
    - `ui.publicDomain` : fe.127.0.0.1.omg.howdoi.website
  - Add configuration option: `logLevel` to set the s3gw-service's
    log verbosity.
  - Defaulted value: `1`
  - (gh#aquarist-labs/s3gw#180)

- UI
  - Add multi-selection support to data tables (gh#aquarist-labs/s3gw#135).

## Fixes

- UI
  - Creating a bucket with spaces crashed the app (gh#aquarist-labs/s3gw#225).
  - Fix URL in the dashboard buckets widget (gh#aquarist-labs/s3gw#240).

## What's Changed

- UI
  - Combine the regular and administrator UI (gh#aquarist-labs/s3gw#175).

- Charts
  - Remove configuration options: `hostname` and `ui.hostname`, both superseded
    by the newly added variables. (gh#aquarist-labs/s3gw#180)

## Breaking Changes

- None

## Known Issues

- Multipart uploads are currently tracked solely in memory. Should the gateway
  be stopped, ongoing multipart uploads will be lost.
- Listing multipart uploads does not account for prefix or delimiters.
