# Release Notes - v0.15.0

This release focuses on stabilizing our continuous integration and release process.
In this context, we have also addressed a number of issues that was affecting our
testing framework when automatically triggered by CI.

This activity, although not introducing a direct improvement consumable by the user,
is crucial to ensure a proper and stable environment for the upcoming major
enhancements the s3gw's team is currently working on.

Obviously, we still continued to address regular issues affecting all the s3gw's
components.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- SFS: Improve error handling and robustness of non-multipart PUT operations.
- SFS: Telemetry: the backend now periodically exchanges data with our upgrade responder.
- UI: Add tags support for objects.

## Fixes

- CI: Various fixes focused on the stabilization and the consistency of the process.
- Tests: Various fixes related with the integration with both the CI and the
  release process.

## Breaking Changes

- None

## Known Issues

- SFS: Non-versioned GETs may observe dirty data of concurrent non-multipart PUTs.
