# Release Notes - v0.12.0

This release contains a bunch of stability fixes in the backend, but also some
new features in the UI. Most notably, the UI can now display prefixes as
directories, bringing back some familiarity to its feel.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- UI: Add support for folder-like view of prefixes in the object explorer
- SFS: Performance improvements by utilizing SQLite's facilities in favor of
  custom mutexes
- SFS: Use SQLite in WAL mode
- SFS: Wrap OP execution in exception handler to avoid crashing on
  non-implemented stubs

## Fixes

- SFS: Improve robustness of SAL-layer errors, which now create the appropriate
  HTTP error codes
- SFS: Gracefully handle out-of-space situations
- Build: Fix missing `.note.ABI-tag` ELF section causing exec format errors on
  some platforms

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues

No known issues
