# Context and Problem Statement

We want to share the responsibility of release management. Each week of the
release, one team member will be responsible for all release-related tasks. This
team member will be the release captain.

This document defines and agrees on the responsibilities of said release
captain.

## Considered Options

### Responsibilities of a Release Captain

The release captain is responsible for the content of a release. That means
taking appropriate measures to include all necessary fixes and features as well
as delivering sane and functional container images. The release captain is also
responsible for describing the changes of the new release in the release notes.

### Create a Release

- Create a release branch for a given release for the `ceph` & `s3gw-ui`
  repositories. All bugfixes will be backported to the relevant repo. The name
  of the branch should reflect the current milestone (ie `0.8.0`). In the Ceph
  repo we need to prepend `s3gw-`(ie `s3gw-0.8.0`)
- Aggregate changelog and create s3gw/docs/release-notes/s3gw-vx.x.x.md Use
  previous release notes for guidance.
- Change s3gw/docs/release-notes/latest to point to the new release notes (this
  will be used by automation)
- Update all subrepos changelog from `Unreleased` to the current release date.
- Bump all subrepos repos to the desired git ref
- Push these changes
- Create a version tag in the s3gw repo (this triggers the release pipeline,
  which creates the container and a draft release)
- After waiting for the release pipeline to finish building, go to the release
  page and make the release public

### Sanity Checks

- s3gw container published (ghcr.io/aquarist-labs/s3gw:vx.x.x)
- s3gw-ui container published (ghcr.io/aquarist-labs/s3gw-ui:vx.x.x)
- The container tags ghcr.io/aquarist-labs/s3gw:latest and
  ghcr.io/aquarist-labs/s3gw-ui:latest should exist and point to their
  respective latest container.
- Chart updated
- Release notes

## Decision Outcome

The proposed steps are approved and this document can be used as reference.
