# Release Notes - v0.10.0

This release contains several important changes to the UI and the charts as well
as the backend.
In addition to that multiple issues in documentation and build tools were fixed.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- UI:
  - Display more information on objects
  - Table columns have a show/hide button
  - Add search field to data tables
  - Add progress indicator for the loading process of the Angular app
- Charts:
  - Support certificate manager for handling certificates on endpoints
  - Support cluster internal access with TLS enabled
- SFS/Backend
  - Add status page
  - Add metrics page exposing s3gw internal data to monitoring (e.g. Prometheus)

## Fixes

- UI:
  - A page reload now does not disable the admin switch
  - Persist data tables pagination settings

## Breaking Changes

No known breaking changes
