# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- added multipart upload tests.
- rearranged python test names to follow a `test-*.py` convention.
- created top-script to run smoke tests and python tests.

### Changed

- libfmt system package updated to version 9 in gateway's Dockerfiles.

## [0.6.0] - 2022-09-29

- added '--longhorn-custom-settings' option to env/setup.sh to install longhorn
  using custom settings.
- added the ability to build a s3gw-test image able to run google-tests related to
  radosgw sfs backend development.

## [0.4.0] - 2022-09-01

### Added

- added '--no-s3gw' option to env/setup.sh to install K3s only.
- added '--import-local-image' and '--import-local-ui-image' options to
- added `tests/s3gw-buckets-rest-api-test.py` to test bucket related rest calls.

### Changed

- relocate docs to [s3gw repository](https://github.com/aquarist-labs/s3gw/docs).
  import local s3gw and s3gw-ui images into a running K3s.
- Boost system packages updated to version 80_0 in gateway's Dockerfiles.

## [0.3.0] - 2022-08-04

## [0.2.0] - 2022-07-28

## [0.1.0] - 2022-07-14

- Initial release.
