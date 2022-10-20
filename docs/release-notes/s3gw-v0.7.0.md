# Release Notes - v0.7.0

This release adds several bug fixes, together with UI improvements. In
addition, the documentation, testing and other have been improved.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- UI
  - Add basic bucket management features for non-admin users.
    They can create/update/delete buckets.

## Fixes

- S3GW
  - Fixed queries to users by access key when user has multiple keys.
  - Fixed a circular lock dependency, which could lead to a deadlock when
    aborting multiparts for an object while finishing a different object.

- UI
  - Login page does not show error messages.

## What's Changed

- UI:
  - Continuing to adapt the UI according to the Rancher UI design kit.
  - Error reporting has been improved.

- Charts
  - Properly label all components of the chart to give helm hints about what is part
    of the chart.
  - Redesing registry access variables to be usable with private registries
  - Improve rancher questions to guide the installation in a more user friendly form

## Breaking Changes

- None

## Known Issues

- Multipart uploads are currently tracked solely in memory. Should the gateway
  be stopped, on-going multipart uploads will be lost.
- Listing multipart uploads does not account for prefix or delimiters.
- Metadata stored in sqlite is no longer compatible with previous versions.
