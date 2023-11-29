# Release Notes - v0.23.0

This release contains significant improvements and new bug fixes. Notably,
this release brings more SQLite efficiency, better consistency when we use
's3gw' vs 'rgw' terminology, and several UI improvements.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related with known issues, one
should feel encouraged to file an issue in our
[Github repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- rgw/sfs: Add SQLite connection pool
- rgw/sfs: Begin transition from sqlite_orm to sqlite_modern_cpp
- rgw/sfs: Rename on-disk database from s3gw.db to sfs.db
- rgw/sfs: Standardize log levels
- ui: Subpath support for better Longhorn integration
- ui: Allow deletion of specific objects
- ui: Support configuring S3 addressing style
- ui: Identify instance associated with the running UI

## Fixes

- rgw/sfs: Improve attribute setting
- rgw/sfs: Init bucket mtime
- rgw/sfs: Delete multiparts only on existing buckets
- rgw/sfs: Mark all OPEN versions DELETED on startup
- rgw/sfs: Ignore deleted buckets when listing multiparts
- rgw/sfs: Remove dangling multipart build files in case of error
- ui: Prevent user from logging out when deleting a locked object version
- ui: Fix error when deleting an object in an unversioned bucket
- ui: Fix buggy prefix handling in REST API
- ui: Fix object deletion behavior when objects share the same base pattern

## Breaking Changes

One major user-facing behavior has changed for those relying on the vanilla
container images. If you rely on the Helm Chart you should not be affected.

- The `s3gw` container's entrypoint is now a wrapper script, `entrypoint.sh`,
  abstracting some options and functionality. Options provided when running the
  container image must now conform to the new script, although previous options
  can still be passed directly to the underlying `rgw` after `--`. For more
  information, please check the documentation at [Advanced Usage][1].

## Known Issues

- No known issues.

[1]: https://s3gw-docs.readthedocs.io/en/latest/advanced-usage/
