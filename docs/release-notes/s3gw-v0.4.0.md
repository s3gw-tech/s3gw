# Release Notes - v0.4.0

With v0.4.0 we introduce Object Versioning in the Gateway.
Other than this, we are improving the project in almost all aspects,
from the UI and Helm Charts to the continuous Integration and Testing.
Read the subsequent sections for all the changes in detail.

This release is meant for testing and feedback gathering. It is not
recommended for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our [GitHub repository][repo-url].

## Features

- Docs: New, easy-to-read documentation. Found [here][docs-url]
- S3GW: Object Versioning
- S3GW: Enable / Disable bucket versioning
- S3GW: When versioning is enabled and a new object is pushed it creates a new
  version, keeping the previous one
- S3GW: Objects versions list
- S3GW: Download specific version (older versions than the last one)
- S3GW: Object delete (delete mark is added in a new version)
- UI: The ability to configure none/unlimited buckets per user
- UI: User/Bucket Quota configuration per user
- UI: Basic bucket management support
- UI: Project branding
- Charts: Set `system` flag for default user
- Charts: Documentation to support PVC selection

## Fixes

- S3GW: An issue where the creation time of a bucket was displayed as the
  current machine time.
- S3GW: The JSON response for creation bucket rest call for `system` users
- Charts: Configured UI and added information about CORS

## Breaking Changes

- None

## Known Issues

[repo-url]: https://github.com/aquarist-labs/s3gw
[docs-url]: https://s3gw-docs.readthedocs.io/en/latest/
