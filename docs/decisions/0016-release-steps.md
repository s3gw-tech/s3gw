# Release Steps for the s3gw project

## Context and Problem Statement

Releasing is an essential process for the `s3gw` project. Given the project is
composed by various sub-projects, that need to be prepared, tested, and
eventually released, the Release Process is not trivial.

This document defines and agrees on the steps required to release the `s3gw`
project, and results from splitting the [Release Process ADR][process_adr] in
three documents: [Release Methodology][methodology_adr], Release Steps (this
document), and [Release Testing][testing_adr].

This document supersedes the [Release Process ADR][process_adr].

## Note Before

It is important to be familiar with the various concepts defined in the
[Release Methodology ADR][methodology_adr], and the release validation process
described in [Release Testing][testing_adr].

There are five repositories involved in the release process:

- [`s3gw`][repo_s3gw]: Where most of our tooling and infrastructure scripts live.
- [`s3gw-ui`][repo_ui]: The User Interface for `s3gw`.
- [`s3gw-charts`][repo_charts]: Containing the Helm Chart to deploy `s3gw` in a
  Kubernetes context.
- [`ceph`][repo_ceph]: Where the core backend of `s3gw` lives.
- [`cosi-driver`][repo_cosi]: The COSI driver for Kubernetes.

Of these, we refer to `s3gw` as the project's repository, and the remaining four
to be sub-projects of the `s3gw` project.

### [Note on the `s3gw-charts` repository](s3gw-charts-note)

The Helm Chart requires the containers to be available for download from Quay
before it can be published. Therefore, we can't trigger the `s3gw-charts`
repository release workflow before the various containers have been built.

In turn, the containers are only built during the `s3gw` repository's release
workflow.

However, to ensure the consistency of the release branch (and its various
release versions), we must guarantee that the `charts` submodule in the `s3gw`
repository is pointing to a commit representing the Helm Chart at the specific
version we are releasing.

This becomes a bit of a _chicken and egg_ problem: we need to have a commit in
the `s3gw-charts` repository we can point to from the `s3gw` repository, so we
can build the containers, but we also need the containers first before we can
trigger the release workflow in `s3gw-charts`.

This is overcome by having the release workflow being triggered _on push_ to
branches following a specific format in the `s3gw-charts` repository, but using
a different branch to perform all required actions until then.

Thanks to `git`'s nature, as long as the commit is _somewhere_ in the
repository, regardless of branch, it is a valid commit we can point to from the
`s3gw` repository's `charts` submodule.

Therefore, we will be using branches in the format `s3gw-vX.Y` for preparatory
release actions, and a branch in the format `vX.Y` when it is time to trigger
the chart's release workflow. Keep this in mind while following the release
process steps.

## Step-by-Step Release Process

This section describes the release process, step by step. For a condensed
version of the release process, command by command, see the later section
[Manual Process](#manual-process).

For example purposes, we assume we are releasing version `0.99.0`.

1. For each sub-project repository, and for the `s3gw` repository, branch off
   `main` to a new release branch. This can be achieved via the GitHub web
   UI[^1], or by pushing the new branch to the repository via the CLI[^2].
   Release branch names follow the `s3gw-vX.Y` convention; i.e., `s3gw-v0.99`.

2. Ensure all sub-project repositories are checked out at the `s3gw-v0.99`
   branch. Assuming `upstream` as the source remote, and that the branching was
   performed through the GitHub web UI (i.e., not manually through the CLI),
   checking out looks like the following:

   ```shell
   git checkout upstream/s3gw-v0.99 -b s3gw-v0.99
   ```

3. In the `s3gw-charts` repository, on branch `s3gw-v0.99`, update the Chart
   version to `0.99.0`. The Chart file can be found in
   `charts/s3gw/Chart.yaml`.

4. Stage and commit the updated Chart.

   ```shell
   git add charts/s3gw/Chart.yaml
   git commit --signoff --gpg-sign -m "Release v0.99.0"
   ```

5. For each sub-project, tag the release branch as a release candidate[^3]. Keep
   in mind that when tagging, creating a signed and annotated tag[^4] is crucial.

   ```shell
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" s3gw-v0.99.0-rc1
   ```

6. For each sub-project, push the `s3gw-v0.99` branch, as well as the newly
   created tag.

   ```
   git push upstream s3gw-v0.99
   git push upstream --tags s3gw-v0.99.0-rc1
   ```

7. In the `s3gw` repository's newly created release branch, update the various
   sub-projects' state to reflect the now existing tags. This can be achieved in
   by checking out the appropriate tag on each individual sub-project's
   submodule directory. A commit will be necessary to persist the
   changes. The following shows a trimmed example of what to do.

   ```shell
   # in the root of the s3gw repo, branch s3gw-v0.99
   cd ceph/
   git remote update
   git checkout origin/s3gw-v0.99.0-rc1
   cd ..
   git add ceph/

   # repeat for the several other sub-projects
   ```

8. Write the release notes for `v0.99.0` into
   `docs/release-notes/s3gw-v.99.0.md` and update the `latest` symlink in
   `docs/release-notes` to point to the newly created file.

9. Commit the changes required for the release candidate.

   ```shell
   git commit --signoff --gpg-sign -m "Release Candidate 1 for v0.99.0"
   ```

10. Tag the `s3gw` repository with the appropriate release candidate tag.
    It is important, that this tag contains only the `vX.Y.Z` version.

    ```shell
    git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" v0.99.0-rc1
    ```

11. Push the release branch and tag. This will trigger the release pipeline,
    creating the various release artifacts and a draft release.

    ```shell
    git push upstream s3gw-v0.99
    git push upstream --tags v0.99.0-rc1
    ```

12. Once the containers have been created and pushed to Quay, it's time to start
    validating the release candidate. Please refer to the
    [Release Testing ADR][testing_adr] before continuing.

13. If any patches needed to be backported at some point since the last release
    candidate, please go back to `step 5.` and increase the release candidate
    version by `1` (i.e., `-rc2`, `-rc3`, etc.). Even if a particular sub-project
    repository has not been changed, it is still crucial to tag it with the new
    release candidate version, for consistency across repositories.

14. Assuming everything goes well, we can now go through `step 5.` but, instead
    of tagging for a release candidate version, we will be tagging for the
    release version.

    ```shell
    git tag --annotate --sign -m "Release v0.99.0" v0.99.0
    git push upstream --tags v0.99.0
    ```

    By pushing the branch with the release tag, we will trigger the release
    workflow that will build the various release artifacts and publish the
    containers on Quay.

15. Once the final release containers have been built, it is time to deal with
    the `s3gw-charts` repository and trigger the Helm Chart release (if you are
    unfamiliar with the problematic, please refer to the
    [this section](#s3gw-charts-note)). To do this, we simply push the contents
    of our `s3gw-v0.99` branch to `v0.99`.

    ```shell
    git push upstream s3gw-v0.99:v0.99
    ```

16. As soon as the Helm Chart has been published on [ArtifactHub][artifacthub],
    we are ready to finalize the release.

    During the release workflow triggered in `step 14.`, a draft release was
    created for `v0.99.0`. This can be found in the [releases page][releases] in
    the `s3gw` GitHub repository web page.

    This release draft was built using the release notes file in the
    `s3gw-v0.99` branch, and will be pre-populated. Editing may be required to
    make it presentable.

    It can now be published.

17. Check if there are release drafts for previous Release Candidates. If so,
    remove them.

18. It is now time to shout about the latest release from the rooftops. A
    release announcement should be sent to the various communication channels
    being used by the project.

    - rancher-users Slack channel `#s3gw`
    - SUSE Slack channel `#discuss-s3gw`
    - project mailing list at `s3gw@suse.com`

    The format for the release announcement can be found in the
    [Release Announcement][#announcement] section.

19. Finally, we need to synchronize the `main` branches of the `s3gw` and the
    `s3gw-charts` repositories with their respective `s3gw-v0.99` branches, so
    the individual `main` branches are up-to-date. This means cherry-picking the
    individual release and release candidate commits into `main`. You will need
    to check for the individual commits SHA1s yourself; you may ask for help
    from the team if you are unsure what to do. A good rule of thumb is to
    cherry-pick those commits that would make the `main` branches represent the
    latest release. For instance, in the `s3gw` repository, this will likely
    involve the commits updating the submodules and the one adding the release
    notes for `v0.99.0`; on the `s3gw-charts` repository, it will mean the
    commit updating the chart version to `0.99.0`.

[^1]:
    For example, for a `v0.99.0` release, for the `s3gw`
    repository, go to the [Branches Page][branches] and click the `New branch`
    button.

[^2]: For example, for a `v0.99.0` release, `git branch --copy main s3gw-v0.99`
[^3]:
    Please refer to [Git's Documentation][git_tags] for more information on
    Tagging.

[^4]:
    Annotated tags keep information about creation time, author, a message,
    are checksummed, and can be signed, being full fledged git objects. For a
    release it is important to keep this information. A lightweight tag, on the
    other hand, is often used for temporary purposes.

## [Manual Process](manual-process)

Assuming we are releasing version `0.99.0`, for every repository, first we need
to branch off `main` to a new branch `s3gw-v0.99.0`. We can do this via the
GitHub web UI or via the CLI. This document describes doing it via the CLI.

1. Branch off `main` into `s3gw-v0.99.0`

   ```shell
   cd /aquarist-labs/s3gw-ceph.git
   git remote update upstream
   git checkout upstream/main -b s3gw-v0.99.0

   cd /aquarist-labs/s3gw-ui.git
   git remote update upstream
   git checkout upstream/main -b s3gw-v0.99.0

   cd /aquarist-labs/s3gw-cosi-driver.git
   git remote update upstream
   git checkout upstream/s3gw -b s3gw-v0.99.0

   cd /aquarist-labs/s3gw-charts.git
   git remote update upstream
   git checkout upstream/main -b s3gw-v0.99.0

   cd /aquarist-labs/s3gw.git
   git remote update upstream
   git checkout upstream/main -b s3gw-v0.99.0
   ```

2. Update the Helm Chart version in
   `/aquarist-labs/s3gw-charts.git/charts/s3gw/Chart.yaml` to `0.99.0`

3. Stage and commit the updated Chart

   ```shell
   cd /aquarist-labs/s3gw-charts.git
   git add charts/s3gw/Chart.yaml
   git commit --signoff --gpg-sign -m "Release v0.99.0"
   ```

4. For each sub-project, tag the release branch as a release candidate, and push
   to upstream

   ```shell
   cd /aquarist-labs/s3gw-ceph.git
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" s3gw-v0.99.0-rc1
   git push upstream s3gw-v0.99
   git push upstream --tags s3gw-v0.99.0-rc1

   cd /aquarist-labs/s3gw-ui.git
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" s3gw-v0.99.0-rc1
   git push upstream s3gw-v0.99
   git push upstream --tags s3gw-v0.99.0-rc1

   cd /aquarist-labs/s3gw-cosi-driver.git
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" s3gw-v0.99.0-rc1
   git push upstream s3gw-v0.99
   git push upstream --tags s3gw-v0.99.0-rc1

   cd /aquarist-labs/s3gw-charts.git
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" s3gw-v0.99.0-rc1
   git push upstream s3gw-v0.99
   git push upstream --tags s3gw-v0.99.0-rc1
   ```

5. In the `s3gw` repository, update the submodules in the `s3gw-v0.99` branch to
   match the tags that were created.

   ```shell
   cd /aquarist-labs/s3gw.git

   cd ceph/
   git remote update origin
   git checkout s3gw-v0.99.0-rc1
   cd ..
   git add ceph/

   cd ui/
   git remote update origin
   git checkout s3gw-v0.99.0-rc1
   cd ..
   git add ui/

   cd cosi-driver/
   git remote update origin
   git checkout s3gw-v0.99.0-rc1
   cd ..
   git add cosi-driver/

   cd charts/
   git remote update origin
   git checkout s3gw-v0.99.0-rc1
   cd ..
   git add charts/
   ```

6. Write the release notes for `v0.99.0` (e.g., `/tmp/s3gw-v0.99.0.md`)

   ```shell
   cd /aquarist-labs/s3gw.git/docs/release-notes
   cp /tmp/s3gw-v0.99.0.md s3gw-v0.99.0.md
   ln -fs s3gw-v0.99.0.md latest
   git add s3gw-v0.99.0.md
   git add latest
   ```

7. Commit changes required for the release candidate, and tag the commit. Note
   that the tag format for the `s3gw` repository is in the `vX.Y.Z` format
   instead of `s3gw-vX.Y.Z` as for the remaining repositories

   ```shell
   cd /aquarist-labs/s3gw.git
   git commit --signoff --gpg-sign -m "Release Candidate 1 for v0.99.0"
   git tag --annotate --sign -m "Release Candidate 1 for v0.99.0" v0.99.0-rc1
   ```

8. Push the release branch and the tag

   ```shell
   cd /aquarist-labs/s3gw.git
   git push upstream s3gw-v0.99.0
   git push upstream --tags v0.99.0-rc1
   ```

9. Once the release workflow finishes, and the containers are available in
   [s3gw's Quay][quay_s3gw], we can start testing the release candidate. Please
   refer to the [Release Testing ADR][testing_adr] for more information

10. If there is a need for further release candidates, go back to `step 4.`, and
    proceed as needed. Otherwise, we can trigger the final release build

    ```shell
    cd /aquarist-labs/s3gw.git
    git tag --annotate --sign -m "Release v0.99.0" v0.99.0
    git push upstream --tags v0.99.0
    ```

11. Once the final release containers have been built, we can then trigger the
    release workflow for the charts repository

    ```shell
    cd /aquarist-labs/s3gw-charts.git
    git push upstream s3gw-v0.99:v0.99
    ```

12. As soon as the Helm Chart has been published on [Artifact Hub][artifacthub],
    we can finalize the release. The next step is to publish the release draft
    that was generated, which can be found in the [releases page][releases].
    There may be drafts for the release candidates as well - delete them

13. Announce the release on the various communication channels. Please refer to
    the [Release Announcement][#announcement] section for more information.

14. Finally, we just synchronize the `main` branches of the `s3gw` and the
    `s3gw-charts` repositories with their respective `s3gw-v0.99` branches, so
    the individual `main` branches are up-to-date. This means cherry-picking the
    individual release and release candidate commits into `main`. You will need
    to check for the individual commits SHA1s yourself; you may ask for help
    from the team if you are unsure what to do

    ```shell
    cd /aquarist-labs/s3gw.git
    git checkout upstream/main -b merge_v0.99_into_main
    git cherry-pick -x --no-signoff <SHA1> [<SHA1>...]
    git push upstream merge_v0.99_into_main

    cd /aquarist-labs/s3gw-charts.git
    git checkout upstream/main -b merge_v0.99_into_main
    git cherry-pick -x --no-signoff <SHA1> [<SHA1>...]
    git push upstream merge_v0.99_into_main
    ```

    And then open a Pull Request on each branch, from their respective
    `merge_v0.99_into_main` branches to `main`, and ask for a review.

## [Release Announcement](announcement)

### via Slack

Announce the release of the s3gw in the following Slack channels:

- SUSE workspace: #discuss-s3gw
- Rancher Users workspace: #s3gw

```
  It's my pleasure to announce the release of :s3gw: S3 Gateway v0.99.0 :tada:

  This release once again includes a couple of exciting changes, most notably:

  - Refactoring of amazing things :male-mechanic:
  - Various UI fixes and improvements :star2:
  - Various chart improvements :helm-intensifies:
  - More awesomeness :awesome:

  Breaking Changes:

  - The on-disk format of the metadata store has changed. Volumes previously
    used with an older version of s3gw are not guaranteed to work with this
    and following versions.

  Get the container images from:

  - quay.io/s3gw/s3gw:v0.99.0
  - quay.io/s3gw/s3gw-ui:v0.99.0
    or just use the :helm: chart
```

### via Email

Announce the release via our s3gw mailing list by sending an email to the list:

```
To: s3gw@suse.com

Subject: Release v0.99.0

  It's my pleasure to announce the release of S3 Gateway v0.99.0

  This release once again includes a couple of exciting changes, most notably:

  - Refactoring of the amazing things
  - Various UI fixes and improvements
  - Various chart improvements
  - More awesomeness

  Breaking Changes:

  - The on-disk format of the metadata store has changed. Volumes previously
    used with an older version of s3gw are not guaranteed to work with this
    and following versions.

  Sources for the release are available here[1]
  Get the container images from:

  - quay.io/s3gw/s3gw:v0.99.0
  - quay.io/s3gw/s3gw-ui:v0.99.0

  or just use the helm chart[2]

  [1] https://github.com/aquarist-labs/s3gw/releases/tag/v0.99.0
  [2] https://artifacthub.io/packages/helm/s3gw/s3gw
```

### [Sanity Checks](sanity-checks)

- [ ] `s3gw` container has been published on Quay for `vX.Y.Z`.
- [ ] `s3gw-ui` container has been published on Quay for `vX.Y.Z`.
- [ ] both containers are appropriately tagged with `vX.Y.Z` on Quay.
- [ ] both containers are tagged with `latest` on Quay.
- [ ] `latest` version containers are the same as the `vX.Y.Z` containers on
      Quay.
- [ ] Helm Chart has been properly updated for `vX.Y.Z`.
- [ ] Helm Chart for `vX.Y.Z` is visible on [ArtifactHub][10]. This can take
      about 20 minutes.
- [ ] The release notes are in place, both on the `s3gw` repository's `main`
      branch and on the `s3gw-vX.Y` branch.

[process_adr]: /docs/decisions/0007-release-process.md
[methodology_adr]: /docs/decisions/0015-release-methodology.md
[testing_adr]: /docs/decisions/0017-release-testing.md
[quay_url]: https://quay.io
[repo_ui]: https://github.com/aquarist-labs/s3gw-ui/
[repo_charts]: https://github.com/aquarist-labs/s3gw-charts/
[repo_s3gw]: https://github.com/aquarist-labs/s3gw/
[repo_ceph]: https://github.com/aquarist-labs/ceph/
[repo_cosi]: https://github.com/aquarist-labs/s3gw-cosi-driver
[artifacthub]: https://artifacthub.io/packages/helm/s3gw/s3gw
[releases]: https://github.com/aquarist-labs/s3gw/releases
[branches]: https://github.com/aquarist-labs/s3gw/branches
[git_tags]: https://git-scm.com/book/en/v2/Git-Basics-Tagging
[s3gw_quay]: https://quay.io/organization/s3gw
