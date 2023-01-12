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

- Create a development branch for a next release in the `ceph`, `s3gw`,
  `s3gw-ui`, `s3gw-tools` and `s3gw-charts` repositories if necessary.
  The name of the branch should reflect the current milestone. Branching
  can be done easily by visiting the branches page of the sub-project on
  GitHub. E.g. visit the [s3gw-ui branches][1] page, click the `New branch`
  button and enter `s3gw-v0.8.x`.
  All bugfixes will be done in the `main` branches of the sub-projects and
  then backported to the `s3gw-vN.N.x` development branch afterwards.
- Update the chart version to `N.N.N` in `s3gw-charts/charts/s3gw/Chart.yaml`,
  e.g. `0.8.0`. Create a PR including these changes for the `s3gw-vN.N.x`
  development branch.

### Create a Release

After the testing phase the following actions need to be done:

- Update the changelog from `Unreleased` to the current release date for each
  sub-project `ceph`, `s3gw-ui`, `s3gw-tools` and `s3gw-charts` in their
  corresponding development branch. You will find the changelog in the
  root folder of the sub-projects or below `src/rgw/store/sfs/` for `ceph`.
  Create a new PR out of these changes for each sub-project. These changes
  will be merged into `main` with separate PRs at a later date.
- After all previous PRs have been merged, the development branches of the
  `ceph`, `s3gw-ui`, `s3gw-tools` and `s3gw-charts` sub-projects need to be
  [tagged][2], e.g.:

```bash
cd ~/git/s3gw-ui/
git checkout -b v0.8.x-upstream upstream/s3gw-v0.8.x
git tag --annotate --sign -m "Release v0.8.0" s3gw-v0.8.0
git push upstream tag s3gw-v0.8.0

cd ~/git/ceph/
git checkout -b s3gw-v0.8.x-upstream aquarist-labs-upstream/s3gw-v0.8.x
git tag --annotate --sign -m "Release s3gw-v0.8.0" s3gw-v0.8.0
git push aquarist-labs-upstream tag s3gw-v0.8.0
```

- Aggregate the changelog and create `s3gw/docs/release-notes/s3gw-vN.N.N.md`
  in the corresponding development branch. Use previous release notes for
  guidance.
- Change `s3gw/docs/release-notes/latest` to point to the new release notes
  (this will be used by automation).

```bash
cd ~/git/s3gw/docs/release-notes/
ln -sf s3gw-v0.8.0.md latest
```

- Bump all branches of the sub-projects in `s3gw/.gitmodules` by using the
  previously created tags. Finally, run the following command to update the
  submodules.

```bash
cd ~/git/s3gw/
git submodule update --init --remote --merge
```

- Commit these changes via PR into the `s3gw-vN.N.x` development branch.
- After the PR has been merged, create an annotated and signed
  [version tag][2] `s3gw-vN.N.N` in the `s3gw` repository (this triggers
  the release pipeline, which creates the container and a draft release).

```shell
cd ~/git/s3gw/
git checkout -b v0.8.x-upstream upstream/s3gw-v0.8.x
git tag --annotate --sign -m "Release v0.8.0" s3gw-v0.8.0
git push upstream tag s3gw-v0.8.0
```

- Merge the changes of the `s3gw` release branch into `main`.

```bash
cd ~/git/s3gw/
git fetch --tags upstream
git checkout main -b merge_w_v0.8.0
git rebase upstream/main
git merge --signoff v0.8.0
```

  Create a new PR out of these changes.

- Merge the changes in the release branch of the `ceph`, `s3gw-ui`, `s3gw-tools`
  and `s3gw-charts` sub-projects into `main`, e.g.:

```bash
cd ~/git/s3gw-ui/
git fetch --tags upstream
git checkout main -b merge_w_v0.8.0
git rebase upstream/main
git merge --signoff v0.8.0

cd ~/git/ceph/
git fetch --tags aquarist-labs-upstream
git checkout s3gw -b merge_w_s3gw-v0.8.0
git rebase aquarist-labs-upstream/s3gw
git merge --signoff s3gw-v0.8.0
```

  Create a new PR out of these changes.

- Create a [draft release][3] and choose the previously created tag.
  File the form with the following data:
  - Use `vN.N.N` as title, e.g. `v0.8.0`.
  - Paste the content of `s3gw/docs/release-notes/s3gw-vN.N.N.md` as
    release notes.

- After waiting for the [release pipeline][4] to finish building, go to the
  release page and make the draft release public.

### Sanity Checks

- `s3gw` container published (quay.io/s3gw/s3gw:vN.N.N).
- `s3gw-ui` container published (quay.io/s3gw/s3gw-ui:vN.N.N).
- The container tags `quay.io/s3gw/s3gw:latest` and
  `quay.io/s3gw/s3gw-ui:latest` should exist and point to their
  respective latest container.
- Chart updated.
- Release notes.

## Decision Outcome

The proposed steps are approved and this document can be used as reference.

[1]: https://github.com/aquarist-labs/s3gw-ui/branches
[2]: https://git-scm.com/book/en/v2/Git-Basics-Tagging
[3]: https://github.com/aquarist-labs/s3gw/releases/new
[4]: https://github.com/aquarist-labs/s3gw/actions/workflows/release.yaml
