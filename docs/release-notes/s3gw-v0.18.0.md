# Release Notes - v0.18.0

This release contains numerous fixes for the UI and a refactoring of the object
versioning implementation. 

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- UI: Add a hint to the prefix field in the lifecycle rule dialog (#600)
- UI: Enhance branding support (#572)
- SFS: Implement new versioning design (#378, #472, #547, #526, #524, #519)

## Fixes

- UI: Deleting a versioned object is not properly implemented (#550)
- UI: Do not delete object by version (#576)
- UI: Prevent the restoring of the deleted object version (#583)
- UI: Creating an enabled lifecycle rule is not working (#587)
- UI: Disable download button for deleted objects (#595)
- UI: Do not close datatable column menu on inside clicks (#599)
- Chart: Update logo and source URLs (#570)
- Chart: Validate email for tls issuer (#596)
- Chart: Fix installation failure when publicDomain is empty (#602)

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues
