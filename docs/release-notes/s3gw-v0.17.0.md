# Release Notes - v0.17.0

This release contains a number of changes to the internal data structures and
metadata schema in preparation for a more streamlined versioning and multipart
implementation. In addition to that, the UI received a number of bug fixes,
quality of life improvements and a stylistic overhaul, including the logo and
colorscheme. The UI also received a large number of end-to-end tests as well as
an update to the Angular version.

This release is meant for testing and feedback gathering. It is not recommended
for production use.

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our
[GitHub repository](https://github.com/aquarist-labs/s3gw/issues/new/choose).

## Features

- UI: Branding Support (#552)
- UI: Upgrade to Angular 15 (#513)
- UI: Adapt logo and style (#530)
- UI: Various improvements

## Fixes

- UI: Fix incorrect pagination when using search/filters (#559)
- UI: Fix search function only searching a single page (#556)
- UI: Fix redundant 'clear' buttons for search (#554)
- UI: Fix objects with delete markers being displayed (#548)
- Chart: Fix "unsupported protocol" bug for the COSI driver (#511)

## Breaking Changes

- On-disk format for the metadata store changed

## Known Issues
