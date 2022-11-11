# Release Notes - v0.8.0

This release adds several bug fixes, together with UI improvements. In
addition, the documentation, testing and other have been improved.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- S3GW
  - Added a mechanism to check for incompatibility issues without changing the
    original metadata database. When any incompatibility is found it is also shown
    in the logs.
  - Added GC thread deleting permanently removed buckets, its objects and
    versions.

- UI
  - Add basic object management features (gh#aquarist-labs/s3gw#146).
  - Add feature to upload objects into buckets via browser (gh#aquarist-labs/s3gw#167).

## Fixes

- S3GW
  - Fixed segfault when SFSAtomicWriter::complete is called with mtime output
    variable set to nullptr

- UI
  - Fix table pagination issue. Only the first page was visible.

## What's Changed

- S3GW
  - In order to make stat_bucket call available, SFSBucket::update_container_stat
    now returns 0.

- UI
  - Display an error message on the login page if the RGW endpoint is not
    configured correctly.

- Charts
  - Expose `ETag` header in the Traefik s3gw ingress to allow multipart
    uploads via browser (gh#aquarist-labs/s3gw#170).
  - Add the `OPTIONS` method to the Traefik CORS configuration (gh#aquarist-labs/s3gw#188).
  - Fix an issue in the GW ingress related to TLS + wildcard host.

## Breaking Changes

- None

## Known Issues

- Multipart uploads are currently tracked solely in memory. Should the gateway
  be stopped, ongoing multipart uploads will be lost.
- Listing multipart uploads does not account for prefix or delimiters.
