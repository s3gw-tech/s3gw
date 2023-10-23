# Release Notes - v0.22.0

This release contains significant improvements and new bug fixes. Notably,
this release brings improved multipart and sqlite stability.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related with known issues, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- rgw/sfs: Improved SQLite WAL usage
- rgw/sfs: Improved disk usage when copying objects
- rgw/sfs: Improved testing
- ui: Various improvements

## Fixes

- rgw/sfs: Allow multiple delete markers
- rgw/sfs: Fix various multipart transactions
- rgw/sfs: Check number of file descriptors on start
- rgw/sfs: Updated bucket stats
- ui: unable to access UI due to admin ops verifying cert
- ui: The Show/Hide button must have at least one default value
- ui: Dropdown buttons are not rendered correct
- ui: Disable caching of index.html

## Breaking Changes

## Known Issues
