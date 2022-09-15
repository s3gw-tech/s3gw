# Context and Problem Statement

We want to share the responsibility of release management. Each week of the
release, one team member will be responsible for all release-related tasks.
This team member will be the release captain.

This document defines and agrees on the responsibilities of said release captain.

## Considered Options

### Responsibilities of a Release Captain

The release captain is responsible for the content of a release. That means
taking appropriate measures to include all necessary fixes and features as well
as delivering sane and functional container images.
The release captain is also responsible for describing the changes of the new
release in the release notes.

### Create a Release

- Bump versions in Chart (in values.yaml _and_ in Chart.yaml)
- Aggregate change log and create s3gw/docs/release-notes/s3gw-vx.x.x.md
  Use previous release notes for guidance.
- Change s3gw/docs/release-notes/latest to point to the new release notes
  (this will be used by automation)
- Bump all subrepos repos to the desired git ref
- Push these changes
- Create a version tag in the s3gw repo
  (this triggers the release pipeline, which creates the container and a draft
  release)
- After waiting for the release pipeline to finish building, go to the release
  page and make the release public

### Sanity Checks

- s3gw container published (ghcr.io/aquarist-labs/s3gw:vx.x.x)
- s3gw-ui container published (ghcr.io/aquarist-labs/s3gw-ui:vx.x.x)
- chart updated
- release notes

## Decision Outcome

The proposed steps are approved and this document can be used as reference.
