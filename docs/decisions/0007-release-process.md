# Context and Problem Statement

Releasing is an essential process for the `s3gw` project. Given the project is
composed by various sub-projects, that need to be prepared, tested, and
eventually released, the Release Process is not trivial.

This document defines and agrees on the Release Process for the `s3gw` project,
including the steps to be taken on its individual sub-projects, and results
from several iterations defining the Release Process (previously kept in the
[Release Captain ADR](/decisions/0004-release-captain)). The previous
document suffered significant changes since its inception, being modified for
almost every release we have had; we are hoping the present document will
benefit from more stability.

## Definitions

Throughout this document we will often refer to certain things or terms. Below
we define what they mean.

- Version: the state of a given project, at a specific point in time.

- Release Candidate: the tentative set of deliverables from the various `s3gw`
  sub-projects' repositories at a certain version. It may become the final Release.

- Release: the set of deliverables from the various `s3gw` sub-projects'
  repositories at a certain version, published, and accompanied by a
  Release Statement.

- Release Statement: a document associated with a given Release, detailing the
  version being released, and a Changelog.

- Changelog: a list of significant changes that merit being communicated to
  stakeholders in a human-consumable format.

- Release Pipeline: the set of automated workflows triggered on a specific
  moment, resulting in a set of containers or artifacts to be released.

- Release Branch: the state of a given project's development branch at a given
  point in time, as a separate named branch in said project's git repository.

- Backport: the act of applying a patch to a Release Branch originated in a
  more recent Release Branch or the development branch.

- Quay: the current container registry of choice, found at [https://quay.io](https://quay.io).

## Architecture of a Release

The `s3gw` project is composed by multiple sub-projects:

- [`s3gw-ui`][1]: The User Interface for `s3gw`.
- [`s3gw-charts`][2]: Containing the Helm Chart to deploy `s3gw` in a Kubernetes
  context.
- [`s3gw`][3]: Where most of our tooling and infrastructure scripts live.
- [`ceph`][4]: Where the core backend of `s3gw` lives.

Releasing `s3gw` is essentially a coordinated process with all the sub-projects,
which need to be prepared at different stages.

For instance, while the `s3gw-ui`, and `ceph` sub-projects can be
prepared independently, the `s3gw-charts` sub-project requires all pieces to be
in place before the final Release is performed. This stems from the Helm Chart
we provide depending on the various containers being published to Quay;
otherwise, the chart being released would point to unavailable containers.

### Versioning

Each release follows [Semantic Versioning][5], with versions being in the format
`vX.Y.Z`.

When dealing with the individual sub-projects' repositories, we use
`s3gw-vX.Y` for release branches and `s3gw-vX.Y.Z` for version tags.
The `s3gw-` prefix in the sub-projects is needed to avoid naming conflicts with
existing tags in the `ceph` repo.
It is particularly important to understand the difference between a release
branch and a version tag.

A release branch represents the tree upon which the release `vX.Y` is based on,
and once created becomes immutable except for bug fixes (by backporting from the
main development branch). The version tags specify the point at which a given
release branch is released. A release branch may have multiple version tags
throughout the duration of its support lifecycle, as bug fixes are backported to
that particular release.

### Branching

A release represents a point in time of each sub-project's repositories. To keep
track of the state of a sub-project's state at that point in time, we rely on
branches. This allows us to bound the scope of a specific release, and makes
maintaining a release easier, especially when we need to release one or more
patch versions on top of the initial release version.

```
     main    s3gw-vX.Y branch
        |    |
        G    o <tag: vX.Y.1>
        |    |
        F    F'
        |    |
        E    o <tag: vX.Y.0>
        |    |
        D    E'
        | .--' vX.Y initial branch
        |/
        C
        |
        B
        |
        A
```

The diagram above represents the branching out of version `vX.Y` from the main
branch for a given sub-project's repository. As one can see, version `X.Y.0` is
released based on the initial branched off history, containing patches `A`, `B`,
and `C`, plus a backport of patch `E`. Later on, version `X.Y.1` is released
containing an additional backport for patch `F`. Both these backports are
assumed to be bug fixes. We thus maintain a stable source of truth for version
`X.Y`, while being able to release versions of said branch at different points
in time.

### Release Candidate

Once we branch out the main branch to a release branch `s3gw-vX.Y`, we have a
given state with which we are comfortable but that still needs to be validated
prior to being released. This validation includes several automated and manual
tests, which are described in [Testing](#testing), but will require release
containers and artifacts to be built. These will be automatically built by our
infrastructure, but require nonetheless a tag to be associated with it.

Given we can't simply create a version tag for something that hasn't been
validated, we will rely on release candidates instead. Much like a version tag,
a release candidate specifies that a given point in time of a particular release
branch is considered close enough to being released, and takes the form of a tag
in the format `vX.Y.Z-rcN`, with `N` being the number of the release candidate
for version `X.Y.Z`, in ascending fashion. As an example, take the diagram
below.

```
     main    s3gw-vX.Y branch
        |    |
        G    o <tag: vX.Y.1-rc1> <tag: vX.Y.1>
        |    |
        F    F'
        |    |
        E    o <tag: vX.Y.0-rc2> <tag: vX.Y.0>
        |    |
        |    E'
        D    |
        |    o <tag: vX.Y.0-rc1>
        |  /
        |/
        C
        |
        B
        |
        A
```

In this example we can see that, upon branching off from main, we create a
`vX.Y.0-rc1` tag, which will trigger our infrastructure automation and build the
various artifacts needed for a release. In this case we must have identified a
problem, because we had to apply a backport `E'` to the release branch. This
would have led us to create a new release candidate `vX.Y.0-rc2`, which upon
validation was deemed correct and released as `vX.Y.0`. Later on we must have
found that a new bug fix was required, had patch `F'` backported, and a new
release candidate for version `X.Y.1` was created, `vX.Y.1-rc1`. Once this
release candidate was properly validated, version `vX.Y.1` was released.

## Step-by-Step Release Process

1. For each sub-project repository, and for the `s3gw` repository, branch off
   `main` to a new release branch. This can be achieved via the GitHub web
   UI[^1], or by pushing the new branch to the repository via the CLI[^2].
   Release branch names follow the `s3gw-vX.Y` convention.

2. For sub-project `s3gw-ui` and `ceph`, tag the release branch
   as a release candidate[^3]. We do not tag the `s3gw-charts` repository
   because that would trigger a release workflow that we don't want to trigger
   at this time[^4]. The following example assumes `upstream` as the source remote
   for a given sub-project, and `v0.11` as the version being released. Keep in
   mind that when tagging, creating a signed and annotated tag[^5] is crucial.

   ```shell
   git checkout upstream/s3gw-v0.11 -b s3gw-v0.11
   git tag --annotate --sign -m "Release Candidate 1 for v0.11.0" s3gw-v0.11.0-rc1
   git push upstream s3gw-v0.11.0-rc1
   ```

3. In the `s3gw` repository's newly created release branch, update the various
   sub-projects' state to reflect the now existing tags. This can be achieved in
   by checking out the appropriate tag on each individual sub-project's
   submodule directory. A commit will be necessary to persist the
   changes. The following shows a trimmed example of what to do.

   ```shell
   # in the root of the s3gw repo, branch s3gw-v0.11
   cd ceph/
   git remote update
   git checkout origin/s3gw-v0.11.0-rc1
   cd ..
   git add ceph/

   # repeat for the several other sub-projects

   git commit -s -S -m "update submodules for v0.11.0-rc1"
   git submodule update --init --remote --sync
   ```

4. Tag the `s3gw` repository with the appropriate release candidate tag.
   It is important, that this tag contains only the `vX.Y.Z` version.

   ```shell
   git tag --annotate --sign -m "Release Candidate 1 for v0.11.0" v0.11.0-rc1
   ```

5. Push the release branch and tag. This will trigger the release pipeline,
   creating the various release artifacts and a draft release.

   ```shell
   git push upstream s3gw-v0.11
   ```

6. Once the containers have been created and pushed to Quay, it's time to start
   validating the release candidate. Please refer to the
   [Testing Section](#testing) before continuing.

7. If any patches needed to be backported at some point since the last release
   candidate, please go back to `step 2.` and increase the release candidate
   version by `1` (i.e., `-rc2`, `-rc3`, etc.). Even if a particular sub-project
   repository has not been changed, it is still crucial to tag it with the new
   release candidate version, for consistency across repositories.

8. Assuming everything goes well, we can now go through step `2.` but, instead
   of tagging for a release candidate version, we will be tagging for the
   release version.

   ```shell
   git tag --annotate --sign -m "Release v0.11.0" v0.11.0
   git push upstream s3gw-v0.11
   ```

9. At this point we will need to update the Helm Chart to reflect the release
   version. This becomes a bit tricky, because we want the change to be reflected
   in both the `main` branch and the `s3gw-vX.Y` branch on the `s3gw-charts`
   repository. To do this, we will apply a patch to the `main` branch, and then
   backport the change to the release branch.

   First, for `v0.11.0`, the chart version needs to be updated with the specific
   version, at `charts/s3gw/Chart.yaml`. This change should then be committed,
   and a Pull Request of this change opened against `main`.

   Once the Pull Request has been merged, note down the new commit's `SHA`;
   running `git log` should give you its value. We can now change to the
   `s3gw-v0.11` branch, and `cherry-pick` the commit, and finally tag the branch
   with the release version.

   ```shell
   git cherry-pick -x -s -S <SHA>
   git tag --annotate --sign -m "Release v0.11.0" s3gw-v0.11.0
   git push upstream s3gw-v0.11
   ```

10. With all sub-project repositories ready to be released, it's time to prepare
    the `s3gw` repository for a release. Much like what we did for the
    `s3gw-charts` repository, we will have to apply a patch on the `main` branch
    first, and then backport it to the release branch: this time to keep track
    of the `CHANGELOG`.

    First step, we need to go to the [Current CHANGELOG][8] page on the
    repository's Wiki, and copy the contents for the release version being
    handled to a file at `docs/release-notes/s3gw-vX.Y.Z.md`. Keep in mind the
    release notes should be easily consumable by a human. Feel free to take
    inspiration on previous release notes, and maintain consistency with them.
    We should also ensure the symbolic link at
    `docs/release-notes/s3gw-latest.md` is updated to point to the newly created
    file. It is crucial that the resulting commit includes these two changes.

    Creating a Pull Request against `s3gw`'s `main` branch is the next step.
    Once that has been merged, note down the new commit's `SHA`, go back to the
    `s3gw-vX.Y` branch, and cherry-pick the commit, tagging the branch with for
    our specific release.

    ```shell
    git cherry-pick -x -s -S <SHA>
    git tag --annotate --sign -m "Release v0.11.0" s3gw-v0.11.0
    git push upstream s3gw-v0.11
    ```

    By pushing the branch with the release tag, we will trigger the release
    workflow that will build the various release artifacts and publish the
    containers on Quay.

11. During the release workflow, a [release draft][9] will be created. Once the
    release artifacts have finished building, and have been published on Quay,
    we can then copy the contents of the release notes file we created in
    step `10.`, and make the release draft public.

    It is advised that before making the release draft public, the list in
    [Sanity Checks](#sanity-checks) be ensured to hold true.

12. With the release now complete, it is time to shout about it from the
    rooftops. A release announcement should now be sent to the various
    communication channels being used by the project.

    - rancher-users Slack channel `#s3gw`
    - SUSE Slack channel `#discuss-s3gw`
    - project mailing list at `s3gw@suse.com`

[^1]:
    For example, for a `v0.11.0` release, for the `s3gw`
    repository, go to the [Branches Page][6] and click the `New branch` button.

[^2]: For example, for a `v0.11.0` release, `git branch --copy main s3gw-v0.11`
[^3]: Please refer to [Git's Documentation][7] for more information on Tagging.
[^4]:
    While the release workflow on `s3gw-charts` would be triggered, it
    wouldn't run to completion given the version of the chart hasn't increased
    over the tag in the repository.

[^5]:
    Annotated tags keep information about creation time, author, a message,
    are checksummed, and can be signed, being full fledged git objects. For a
    release it is important to keep this information. A lightweight tag, on the
    other hand, is often used for temporary purposes.

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

## [Testing](testing)

To be expanded in the future, or maybe link to a proper testing document.

- [ ] Install the `s3gw-ui` container and sign-in. Perform some actions like
      creating/update/delete users and buckets. Also try uploading/deleting
      objects in buckets.

[1]: https://github.com/aquarist-labs/s3gw-ui/
[2]: https://github.com/aquarist-labs/s3gw-charts/
[3]: https://github.com/aquarist-labs/s3gw/
[4]: https://github.com/aquarist-labs/ceph/
[5]: https://semver.org/
[6]: https://github.com/aquarist-labs/s3gw/branches
[7]: https://git-scm.com/book/en/v2/Git-Basics-Tagging
[8]: https://github.com/aquarist-labs/s3gw/wiki/Current-CHANGELOG
[9]: https://github.com/aquarist-labs/s3gw/releases
[10]: https://artifacthub.io/packages/helm/s3gw/s3gw
