# Release Notest - v0.13.0

This release contains a few new features in the backend an in the UI, including
object locking.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- SFS: Add object locking retention modes.
  Add the ability to set the default bucket retention configuration for both
  GOVERNANCE/COMPLIANCE modes
  Add the ability to set an explicit retention mode on object's versions
- UI: Add support for object locking
- UI: Improve the object browser navigation bar

## Fixes

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues

No known issues
