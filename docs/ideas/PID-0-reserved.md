---
slug: /
status: accepted
tags: [ area/docs ]
updated: 2023-10-13
---

# Project Idea Document (PID)

## Context and Problem Statement

We want to record ideas for features, enhancements, and reasonably sane brain
dumps.

Project Idea Documents (henceforth, PID) are therefore records, much like the
ADRs we use for decisions, but fall on a different category: these are not
decisions made by anyone, just a description of something to be considered for
the future.

## Format

PIDs should observe the following qualities:

- Easy to read and review
- Include enough information to be understood by others, and its merit assessed
- Reference all relevant GitHub project issues, if they exist
- Be a single file
- File name should follow the `PID-yyyymmdd-title.md` format

PID-0 is the only PID record that is allowed to break the file name convention.

All PIDs should be kept under `/docs/ideas/` in the `s3gw-tech/s3gw`
repository.

### PID Structure

We do not enforce a strict document structure, but it should be easily
understood.

However, the following rules always apply:

- The PID title should always reflect the idea being proposed
- Metadata is required at the beginning of the record

We recommend always starting the document with a `Context and Problem Statement`
section, and finishing with a `References` section if applicable.

### Metadata

All PIDs should include at least the following metadata at the beginning of its
record:

```yaml
---
status: <proposed | accepted | rejected | superseded>
superseded-by: PID-yyyymmdd-foo.md
tags: <area/foo>
updated: <yyyy-mm-dd>
---
```

The `status` fields translate as the following:

- proposed: The idea has been proposed to the project, and, being part of the
  repository after being merged, its proposal status has been granted
- accepted: The idea has been accepted as a work item at some point in time
- rejected: The idea has been rejected at some point in time
- superseded: A new, better idea came up, superseding this one

The `tags` field should reflect **at least** the `area/` to which an idea
applies. Other tags may be provided, as long as they make sense.

The `updated` field should reflect the last date a given PID was updated.
