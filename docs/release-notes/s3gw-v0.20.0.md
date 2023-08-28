# Release Notes - v0.20.0

This release contains significant improvements and new bug fixes, particularly
in the s3gw backing store. Notably, this release brings garbage collection,
improved bucket listing, including filtering, and conditional GETs.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related with known issues, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- rgw/sfs: Query-based version listing
- rgw/sfs: Support conditional GETs
- rgw/sfs: New garbage collection implementation
- rgw/sfs: Change on-disk file format, add suffixes
- ui backend: Parity with operations required by UI

## Fixes

- rgw/sfs: Fix warnings after enabling more compilation flags
- rgw/sfs: Several code cleanup efforts
- rgw/sfs: use global part id for multipart parts

## Breaking Changes

- On-disk format for both metadata and data store have changed.

## Known Issues
