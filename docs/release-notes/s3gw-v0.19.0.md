# Release Notes - v0.19.0

This release contains various fixes and improvements in the backend. Most
notably, error handling, multipart handling and internal bookkeeping of objects
has improved.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- rgw/sfs: Log SQLite error / warning messages
- rgw/sfs: Add SQLite retries and error handling
- rgw/sfs: Improve multipart handling
- ui backend: Add endpoints for user management
- ui backend: Add bucket management endpoints
- ui frontend: Allow creating admin users

## Fixes

- rgw/sfs: Fix Invalid argument exception on exit with telemetry off
- rgw/sfs: Fix delete bucket when not empty
- rgw/sfs: Abort on-going multiparts on bucket removal
- rgw/sfs: Fix bucket listing
- rgw/sfs: Various fixes to object state transitions
- ui frontend: Fix table header on zoom-in
- ui frontend: Fix bucket deletion dialogue in `Administrator` mode
- ui frontend: Fix creating keys for users

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues
