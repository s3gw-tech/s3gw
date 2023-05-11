# Release Notes - v0.16.0

This release cycle focused on architecture adjustments to the s3gw service's
backend store (SFS), which will be reflected on upcoming releases.

Most noteworthy outcome of this release is the initial COSI support for s3gw.
This can be enabled via the Helm Chart.

We have also disabled user and bucket quotas via the UI. Quotas are currently
not supported by the s3gw service, and have been kept in the UI to demonstrate
what we believe to be the right approach to them. As the backend development
progresses, quotas will be re-enabled when the right time comes.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- Kubernetes: Add experimental COSI support.
- UI: Add new experimental python backend for the UI.
- UI: Disable bucket and user quotas in the UI.

## Fixes

- None

## Breaking Changes

- None

## Known Issues

- SFS: Non-versioned GETs may observe dirty data of concurrent non-multipart
  PUTs.
