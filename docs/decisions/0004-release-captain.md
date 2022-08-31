# Context and Problem Statement

We want to share the responsibility of release management. Each week of the
release, one team member will be responsible for all release-related tasks.
This team member will be the release captain.

This document defines and agrees on the responsibilities of said release captain.

## Considered Options

### Steps to follow on a release

- Tag the s3gw repository main branch with version: vX.Y.Z
- Changelogs for the different repositories. The release captain will liaise
with the developers to ensure they are updated
  - [Ceph](https://github.com/aquarist-labs/ceph/blob/s3gw/src/rgw/store/sfs/CHANGELOG.md)
  - [Tools](https://github.com/aquarist-labs/s3gw-tools/blob/main/CHANGELOG.md)
  - [UI](https://github.com/aquarist-labs/s3gw-ui/blob/main/CHANGELOG.md)
  - [Charts](https://github.com/aquarist-labs/s3gw-charts/blob/main/CHANGELOG.md)
- Build UI container
  - Push UI container's image on ghcr.io/aquarist-labs/s3gw-ui:latest
  - Push UI container's image on  ghcr.io/aquarist-labs/s3gw-ui:vX.Y.Z
- Build Gateway container
  - Push Gateway container's image on ghcr.io/aquarist-labs/s3gw:latest
  - Push Gateway container's image on ghcr.io/aquarist-labs/s3gw:vX.Y.Z
- Create release notes in the s3gw main repository
  - Use [this release](https://github.com/aquarist-labs/s3gw/releases/tag/v0.3.0)
  as a template
  - Add relevant information coming from the previously updated changelog
  documents

## Decision Outcome

The proposed steps are approved and this document can be used as reference.
