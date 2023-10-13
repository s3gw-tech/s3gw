# Release Methodology for the s3gw project

## Context and Problem Statement

Releasing is an essential process for the `s3gw` project. Given the project is
composed by various sub-projects, that need to be prepared, tested, and
eventually released, the Release Process is not trivial.

This document defines and agrees on the Release Methodology for the `s3gw`
project, and results from splitting the [Release Process ADR][process_adr] in
three documents: methodology (this document), [Release Steps][steps_adr], and
[Release Testing][testing_adr].

This document supersedes the [Release Process ADR][process_adr].

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

- Quay: the current container registry of choice, found at [https://quay.io][quay_url].

## Architecture of a Release

The `s3gw` project is composed by multiple sub-projects:

- [`s3gw-ui`][1_1]: The User Interface for `s3gw`.
- [`s3gw-charts`][1_2]: Containing the Helm Chart to deploy `s3gw` in a Kubernetes
  context.
- [`s3gw`][1_3]: Where most of our tooling and infrastructure scripts live.
- [`ceph`][1_4]: Where the core backend of `s3gw` lives.
- [`cosi-driver`][1_5]: The COSI driver for Kubernetes.

Releasing `s3gw` is essentially a coordinated process with all the sub-projects,
which need to be prepared at different stages.

For instance, while the `s3gw-ui`, and `ceph` sub-projects can be
prepared independently, the `s3gw-charts` sub-project requires all pieces to be
in place before the final Release is performed. This stems from the Helm Chart
we provide depending on the various containers being published to Quay;
otherwise, the chart being released would point to unavailable containers.

### Versioning

Each release follows [Semantic Versioning][1_6], with versions being in the format
`vX.Y.Z`.

When dealing with the individual sub-projects' repositories, we use
`s3gw-vX.Y` for release branches and `s3gw-vX.Y.Z` for version tags.
The `s3gw-` prefix in the sub-projects is needed to avoid naming conflicts with
existing tags in the `ceph` repository.
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
        G    o <tag: s3gw-vX.Y.1>
        |    |
        F    F'
        |    |
        E    o <tag: s3gw-vX.Y.0>
        |    |
        D    E'
        | .--' s3gw-vX.Y initial branch
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
tests, which are described in [Release Testing][testing_adr], but will require release
containers and artifacts to be built. These will be automatically built by our
infrastructure, but require nonetheless a tag to be associated with it.

Given we can't simply create a version tag for something that hasn't been
validated, we will rely on release candidates instead. Much like a version tag,
a release candidate specifies that a given point in time of a particular release
branch is considered close enough to being released, and takes the form of a tag
in the format `s3gw-vX.Y.Z-rcN`, with `N` being the number of the release
candidate for version `X.Y.Z`, in ascending fashion. As an example, take the
diagram below.

```
     main    s3gw-vX.Y branch
        |    |
        G    o <tag: s3gw-vX.Y.1-rc1> <tag: s3gw-vX.Y.1>
        |    |
        F    F'
        |    |
        E    o <tag: s3gw-vX.Y.0-rc2> <tag: s3gw-vX.Y.0>
        |    |
        |    E'
        D    |
        |    o <tag: s3gw-vX.Y.0-rc1>
        |  /
        |/
        C
        |
        B
        |
        A
```

In this example we can see that, upon branching off from main, we create a
`s3gw-vX.Y.0-rc1` tag, which will trigger our infrastructure automation and
build the various artifacts needed for a release. In this case we must have
identified a problem, because we had to apply a backport `E'` to the release
branch. This would have led us to create a new release candidate
`s3gw-vX.Y.0-rc2`, which upon validation was deemed correct and released as
`s3gw-vX.Y.0`. Later on we must have found that a new bug fix was required, had
patch `F'` backported, and a new release candidate for version `X.Y.1` was
created, `s3gw-vX.Y.1-rc1`. Once this release candidate was properly validated,
version `vX.Y.1` was released.

[process_adr]: /docs/decisions/0007-release-process.md
[steps_adr]: /docs/decisions/0016-release-steps.md
[testing_adr]: /docs/decisions/0017-release-testing.md
[quay_url]: https://quay.io
[1_1]: https://github.com/aquarist-labs/s3gw-ui/
[1_2]: https://github.com/aquarist-labs/s3gw-charts/
[1_3]: https://github.com/aquarist-labs/s3gw/
[1_4]: https://github.com/aquarist-labs/ceph/
[1_5]: https://github.com/aquarist-labs/s3gw-cosi-driver
[1_6]: https://semver.org/
