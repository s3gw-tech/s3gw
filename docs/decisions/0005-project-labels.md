# Context and Problem Statement

The goal is to put into place standard labels across all SUSE Rancher projects,
which allows people from multiple spheres of interest to have a single glance
into top-level work.

Issues and labels are used for:

- Tracking defects
- Tracking feature requests
- Planning releases
- Managing workflows
- Reporting stats

The introduction of these changes should have minimum impact on our current
workflow since we are mainly renaming already existing labels. We use custom
fields to define [epics][1] & [milestones][2]. We will carry on using them,
together with the `kind/epic` label, since they are a great way of organizing
the work.

## Considered Options

Labels can be found here: [https://github.com/aquarist-labs/s3gw/labels][3]

### Issue conventions

All issues should be actionable (within a reasonable timeframe). Usage questions
and design brainstorming should happen in GitHub discussions.

### Titles

Issue titles should be short (up to 70 characters), with the most important info
at the front.

### Labels

Label names are simple strings without spaces or special characters (including
emojis) to make it easy to type them into GitHub queries.

Labels are grouped into orthogonal "categories", and ideally, an issue should
have no more than one label from each category, e.g. `kind/bug`,
`area/kubernetes`, `component/ui`.

When an issue seems to require multiple labels from the same category, it is
often a hint that it should be split into multiple issues.

The following list aims to comprehensively document all our labels.

### `area/*`

The `area` category species is the user's visible area that is affected by the
issue. It helps to find a duplicate issue during reporting or the triage
process.

An example is `area/kubernetes`.

### `component/*`

The `component/*` category specifies the part of the implementation that will
need to be modified during the implementation.

An example is `component/ui`.

### `kind/*`

This is the "document kind". Each issue **must** have exactly one `kind/*`
label. The labels `kind/bug` and `kind/enhancement` are being standardized
across SUSE Rancher projects.

#### `kind/bug`

This issue describes a defect in the software. Sometimes it requires a judgement
call, but in general, incomplete functionality, or different behavior from a
similar project should be labelled as `kind/enhancement` instead.

#### `kind/enhancement`

This issue requests additional (or a change in) functionality. The request
typically comes from a user or the PO.

#### `kind/epic`

An epic is an umbrella issue to implement a feature that can span over one or
many release cycles. It includes a work breakdown as a task list for individual
`kind/story` issues.

The epic should include acceptance criteria and link to any documentation and QA
work required to finish the epic.

Any unfinished tasks are not automatically rolled over into the next milestone
at release time; they go back into the backlog and will have to be scheduled
again by the triage team.

#### `kind/story`

A story is an individual work item to implement (part of) a feature. We do not
use `kind/enhancement` for this to avoid diluting the reporting of open feature
requests.

#### `kind/quality`

This issue is about refactoring, adding tests, improving CI. Any activity that
improves the quality of the project, but is neither a bug fix nor a user visible
feature.

### `priority/*`

Not every bug, feature or issue requires having a `priority/` label. We won't
prioritize every ticket since triage is a long process for those actively
participating in it, but it's important to highlight what needs to sorted out
urgently.

- priority/0 – Blocker: For bugs, this is an issue that requires immediate
  attention and is a release blocker.
- priority/1 – Critical/Urgent: For bugs, this is an issue that breaks existing
  functionality but doesn't affect the primary use of the app and should be
  addressed in the next release.
- priority/2 – High priority: For bugs, this is an issue that should be triaged
  amongst other higher priority work.

### `regression`

This label should only be applied to `kind/bug` issues and signifies that some
functionality that was working in a previous release is now broken.

### `release-note`

This label is used to mark all issues within a milestone that should be
explicitly mentioned in the release notes.

### `triage/*`

The `triage/*` category is a bunch of values to indicate why the issue was
closed: `triage/by-design`, `triage/duplicate`, `triage/invalid`,
`triage/not-reproducible`, `triage/unsupported`, and `triage/wont-fix`. All
these should only be applied to closed issues.

### `triage/needs-more-information`

We have requested (and are waiting for) additional information from the issue
creator. We will have to close the issue unless we receive the info.

### `triage/next-candidate`

We've analyzed the issue all the relevant information is available. It will now
be prioritized and added to the release planning.

## Decision Outcome

The proposed steps are approved and this document can be used as reference.

[1]: https://github.com/orgs/aquarist-labs/projects/5/views/14
[2]: https://github.com/orgs/aquarist-labs/projects/5/views/1
[3]: https://github.com/aquarist-labs/s3gw/labels
