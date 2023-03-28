# Release Notes - v0.14.0

This release adds lifecycle management, object locks (legal holds) and an
updated version of the radosgw we use for the backend.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- SFS: Initial lifecycle management support
- SFS: Object Lock - Legal holds
- SFS: Metadata database: Add indices to often queried columns
- SFS: Simplify write state machine. Remove _writing_ object state.
  Writes no longer need to update the object state during IO.
- SFS: Update radosgw to Ceph Upstream 0e2e7d594b8
- UI: Display object data more intuitively
- UI: Enhance user key management page
- UI: Add button to copy the current path of the object browser to the clipboard
- UI: Lifecycle management

## Fixes

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues

No known issues
