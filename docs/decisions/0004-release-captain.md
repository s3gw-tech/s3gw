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

### Prepare a Release

For the testing phase that is done right before the official release, the
following actions need to be done.

- Create a branch for a given release in the `ceph`, `s3gw`, `s3gw-ui`,
  `s3gw-tools` and `s3gw-charts` repositories. This can be done easily via
  the GitHub branches page. E.g. visit the [s3gw-ui branches][1] page, click
  the `New branch` button and enter `v0.8.0`.
  All bugfixes will be done in the `main` branches of the sub-projects and
  then backported to the `vx.y.z` release branch afterwards. The name of the
  branch should reflect the current milestone (i.e. `v0.8.0`).
  In the `ceph` repository we need to prepend `s3gw-` (i.e. `s3gw-v0.8.0`).
- Update the chart version to `x.y.z` in `s3gw-charts/charts/s3gw/Chart.yaml`.
  Create a PR including these changes for the `vx.y.z` release branch.

### Create a Release

After the testing phase the following actions need to be done:

- Update the changelog from `Unreleased` to the current release date for each
  sub-project `ceph`, `s3gw-ui`, `s3gw-tools` and `s3gw-charts` in their
  corresponding `vx.y.z` release branch. You will find the changelog in the
  root folder of the sub-projects or below `src/rgw/store/sfs/` for `ceph`.
  Create a new PR out of these changes for each sub-project. These changes
  will be merged into `main` with separate PRs at a later date.
- Aggregate the changelog and create `s3gw/docs/release-notes/s3gw-vx.x.x.md`
  in the `vx.y.z` release branch. Use previous release notes for guidance.
- Change `s3gw/docs/release-notes/latest` to point to the new release notes
  (this will be used by automation).

  ```shell
  cd ~/git/s3gw/docs/release-notes/
  ln -sf s3gw-v0.8.0.md latest
  ```

- Bump all branches of the sub-projects in `s3gw/.gitmodules`. Finally, run
  the following command to update the submodules.

  ```shell
  cd ~/git/s3gw/
  git submodule update --init --remote --merge
  ```

- Commit these changes via PR into the `vx.y.z` release branch.
- After the PR has been merged, create an annotated and signed [version tag][2]
  `vx.y.z` in the `s3gw` repository (this triggers the release pipeline, which
  creates the container and a draft release).

  ```shell
  cd ~/git/s3gw/
  git checkout -b v0.8.0-upstream upstream/v0.8.0
  git tag --annotate --sign v0.8.0
  ```

- Merge the changes of the `s3gw` release branch into `main`.

  ```shell
  cd ~/git/s3gw/
  git fetch upstream
  git checkout main -b merge_w_v0.8.0
  git rebase upstream/main
  git merge --signoff upstream/v0.8.0
  ```

  Create a new PR out of these changes.
- Merge the changes in the release branch of the `ceph`, `s3gw-ui`, `s3gw-tools`
  and `s3gw-charts` sub-projects into `main`, e.g.:

  ```shell
  cd ~/git/s3gw-ui/
  git fetch upstream
  git checkout main -b merge_w_v0.8.0
  git rebase upstream/main
  git merge --signoff upstream/v0.8.0
  ```

  Create a new PR out of these changes.
- Create a [draft release][3] and choose the previously created tag.
  File the form with the following data:
  - Use `vx.y.z` as title.
  - Paste the content of `s3gw/docs/release-notes/s3gw-vx.x.x.md` as
    release notes.
- After waiting for the release pipeline to finish building, go to the release
  page and make the draft release public.

### Sanity Checks

- `s3gw` container published (ghcr.io/aquarist-labs/s3gw:vx.y.z).
- `s3gw-ui` container published (ghcr.io/aquarist-labs/s3gw-ui:vx.y.z).
- The container tags `ghcr.io/aquarist-labs/s3gw:latest` and
  `ghcr.io/aquarist-labs/s3gw-ui:latest` should exist and point to their
  respective latest container.
- Chart updated.
- Release notes.

## Decision Outcome

The proposed steps are approved and this document can be used as reference.

[1]: https://github.com/aquarist-labs/s3gw-ui/branches
[2]: https://git-scm.com/book/en/v2/Git-Basics-Tagging
[3]: https://github.com/aquarist-labs/s3gw/releases/new
