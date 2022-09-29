# Release Notes - v0.6.0

This release adds several new features, together with UI improvements. In
addition, the documentation, testing and other have been improved.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- S3GW
  - Delete/Undelete objects.
  - Ability to list buckets via admin REST API.
  - Support for bucket ACL.
  - Multipart uploads
  - Objects are stored in metadata using bucket id instead of bucket name.
  - Longhorn custom settings for installation.
  - Ability to build a s3gw-test image able to run google-tests.
- UI
  - Adapt the UI according to the Rancher UI design kit.
- Charts
  - Set up & added chart to
    [Artifacthub.io](https://artifacthub.io/packages/helm/s3gw/s3gw)

## Fixes

- S3GW
  - Show delete markers when listing object versions.

## What's Changed

- UI:
  - Adapt the UI according to the Rancher UI design kit.
- Charts
  - Storage settings redesign to allow using an existing storage class while
    keeping it easy to use Longhorn and local storage with minimal work required
  - Give TLS certificates to UI ingress as well -Enable TLS endpoints for
    Traefik ingress

## Breaking Changes

- None

## Known Issues

- Multipart uploads are currently tracked solely in memory. Should the gateway
  be stopped, on-going multipart uploads will be lost.
- Listing multipart uploads does not account for prefix or delimiters.
- Metadata stored in sqlite is no longer compatible with previous versions.
