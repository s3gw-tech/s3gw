# Contributing

The 5 repositories used for the s3gw are located within our main GitHub
organization.

- Main: <https://github.com/aquarist-labs/s3gw>
- Ceph: <https://github.com/aquarist-labs/ceph>
- Tools: <https://github.com/aquarist-labs/s3gw-tools>
- UI: <https://github.com/aquarist-labs/s3gw-ui>
- Charts: <https://github.com/aquarist-labs/s3gw-charts>

We welcome new feature implementations, patches that fix bugs or code cleanup.

## Clone the Source

You can clone from GitHub with:

git clone git@github.com:aquarist-labs/s3gw-tools

Or:

git clone git://github.com/aquarist-labs/s3gw-tools

This applies to all the repositories.

### Submitting Bugs and Requesting New Features

All bugs and feature requests can be filed in "Issues" in
[the s3gw Project](https://github.com/aquarist-labs/s3gw/issues/new/choose). We
use GitHub templates to manage the requests. You will either select:

- Backlog item
- Bug report
- Feature request

Ensure the appropriate label is selected before submitting your issue.

## Document Your Changes

If you have added or modified any user-facing functionality, such as CLI
commands or their output, then the pull request must include appropriate updates
to documentation and changelog if needed.

It is the submitter's responsibility to make the changes, and the reviewer's
responsibility to make sure they are not merging changes that do not have the
needed updates to documentation/changelog.

## Writing Commit Messages

Git commit messages should start with a maximum 72 character or less summary in
a single paragraph, and prefixed with the module you are changing. For example:

```bash
   backend: add initial README doc
   doc: fix a typo
```

The following paragraph(s) should explain the change in more detail; be as
specific as possible. If the commit message title was too short to fully state
what the commit is doing, use the body to explain not just the "what", but also
the "why".

Your commit _must_ include a `Signed-off-by:` line matching an email address of
the commit's author to comply with our need for a
[Developer Certificate of Origin (DCO)](https://developercertificate.org/). The
DCO is a lightweight way for contributors to certify that they wrote or
otherwise have the right to submit the code they are contributing to the
project. You can append this automatically to your commit message via
`git commit -s`. Our repository checks will refuse to accept the commit
otherwise.

For example:

```bash
   backend: add initial README doc

   This commit introduces the first README doc for aquarist-labs.

   Signed-off-by: Random Developer <random@developer.io>
```

If your changes addresses a bug or feature request, be sure to mention them in
the body of the commit message.
[You can even close the issue automatically!](https://github.blog/2013-01-22-closing-issues-via-commit-messages/)
For example:

```bash
   Fixes: #1

   Signed-off-by: Random Developer <random@developer.io>
```

Finally, please be sure to sign all commits with your GPG key (`git commit -S`).

## Pull Requests

### Pull Request Best Practices

PRs should be opened on branches contained in your fork of
`aquarist-labs/s3gw.git`. PRs should target the `main` branch.

If your PR has only one commit, the PR title can be the same as the commit title
(and GitHub will suggest this). If the PR has multiple commits, do not accept
the title GitHub suggests. Either use the title of the most relevant commit, or
write your own title.

## Contributor Guidelines

Do not merge directly into the `main` branch. It is protected for a reason.

### Reviewing Pull Requests

Each pull request requires at least _one_ review and approval from an active
contributor. The primary function of reviews is to ensure ensure quality.
However, we want pull requests to be viewed quickly to avoid code contributors
being blocked.

We ask that reviewers perform a basic sanity check on all code and documentation
contributions. Consider the following aspects when performing a review:

- Does this make sense?
- Does this code perform what the code contributor has described in the commit
  message?
- Have the CI tests run and passed?
- Does this code require documentation? If so, does it have documentation in the
  commit?
- Does this change need to appear in the changelog? If so, has the changelog
  been updated accordingly?
- Are the comments (if there are any) clear and useful?

All pull requests should be reviewed, even if the request is tagged with the
label `needs-rebase`. At this time, it is imperative that code contributions
move swiftly, and without minor blockers.

Note: If the pull request requires a rebase, it is suitable to approve the pull
request, the pull request will not merge automatically.

If your pull request is not yet in the state where it can be meaningfully
reviewed and merged, please leave it in draft status or tag with the `WIP`
label. You can of course still ask for feedback by manually assigning a reviewer
or pinging them directly at this stage.

### Merging Pull Requests

Before merging, check the following:

- Ensure all CI has run and is passing
- The pull request has been open for 24 hours for an appropriate feedback loop
  time
- At least one reviewer has approved
- There is no outstanding change requests

If all of these are complete, you can merge your own pull request. Please do not
merge a pull request that is not your own unless this action has been previously
discussed with the pull request author.

## Automated Testing

There are GitHub actions configured to run smoke/integration tests automatically
when a pull request is opened.

## CI

There are also GitHub actions configured to build the gateway and development
environments when a pull request is opened.

## Be Respectful

Although technical in nature, the Open Source community is first and foremost
about people. Treat other people with respect. Be kind, be open, respect the
culture of the community you are interacting with and be aware of the diversity
of people in that community. Be aware that, particularly in electronic
communication, you might misunderstand or misinterpret what others are saying or
meaning. The reverse is also true.
