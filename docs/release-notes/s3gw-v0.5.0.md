# Release Notes - v0.5.0

This release add a few small fixes to the last release, especially in the UI.
In addition to that, testing and other development processes have improved quite
a bit.

This release is meant for testing and feedback gathering. It is not
recommended for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our [github
repository](https://github.com/aquarist-labs/s3gw).

## Features

- UI: Add Dashboard widget framework. aquarist-labs/s3gw#91
- UI: Add `Total users` and `Total buckets` Dashboard widgets.
- Chart: The variables `hostnameNoTLS`, `ui.hostname` and `ui.hostnameNoTLS`
  has been added to configure the hostnames of the S3GW and S3GW-UI.
- Chart: Defaulted `ui.enabled` to `true`.

## Fixes

- S3GW: Fixed the admin API request: get-bucket-info where the client was
  receiving an empty response. aquarist-labs/s3gw#87
- UI: Mark the user/bucket quota settings in the user form as non-functional
  because the feature is not properly supported by the S3GW.
  aquarist-labs/s3gw#106
- Chart: Rename the `access_key` and `secret_key` variable names according
  the Helm Chart best practices guide to `accessKey` and `secretKey`.
- Chart: Rename the `enableIngress` variable to `ingress.enabled`.
- Chart: Relocate the variables `imageRegistry_ui`, `imageName_ui`,
  `imageTag_ui` and `imagePullPolicy_ui` to `ui.imageRegistry`,
  `ui.imageName`, `ui.imageTag` and `ui.imagePullPolicy`

## Breaking Changes

- None

## Known Issues

- Multipart uploads don't work
