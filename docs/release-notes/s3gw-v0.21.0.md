# Release Notes - v0.21.0

This release contains significant improvements and new bug fixes. Notably,
this release brings server-side encryption support, conditional copy object,
improvement in profiling.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related with known issues, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- rgw/sfs: Add server-side encryption support
- rgw/sfs: Conditional copy object
- ui : Make use of the UI REST API to prevent CORS issues

## Fixes

- rgw/sfs: Improve sqlite connection handling
- rgw/sfs: Fix missing multipart etag
- rgw/sfs: Fix etag and mtime not being sent with copy object response
- rgw/sfs: Increase build error reporting
- rgw/sfs: Improve profiling (sqlite, garbage collection)
- ui: Prevent switching bucket retention mode from Compliance to Governance

## Breaking Changes

## Known Issues
