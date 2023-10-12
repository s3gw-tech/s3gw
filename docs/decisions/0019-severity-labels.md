# Severity Labels

## Context and Problem Statement

In our current process, we are reviewing our backlog and issues in general during our Backlog Review
meeting which happened once every Release Cycle.
Thus when a new issue is created, we automatically add the label 'waiting/triage' so we can review
it during our next Backlog Review. During the Backlog Review meeting, we collectively set a priority
label (from 0-Highest to 3-Lowest) so we can prioritize our work for the next cycle.
This is not ideal as an issue can be leftover for weeks before it's discussed during the
Backlog Review.

## Solution

To make the review and planning process easier for the Tech Lead, the Engineering Manager and
Engineers, we would like to introduce a new type of Labels: Severity.
The goal is to provide a way for the reporter of an Epic/Issue to provide an estimation of the
impact and help the team to plan an prioritize accordingly.

Distinction between Severity and Priority:

- The severity field describes the impact of a bug. And the reporter is free to set this up
- The priority field describes the importance and order in which an issue should be fixed. Priority
cannot be changed without discussing it with relevant stakeholders.

## Requirements

The severity labels:

- Should be easy to understand and use
- Will be taken into account when prioritizing our issues
- Should be compatible with the Longhorn severity labels
- Should be adaptable to other Rancher projects

## Considered Alternatives

The severity label describes the impact of an issue. And the reporter is free to set this up. All
issues should have a severity label set from now on.

### Longhorn

This is the current severity labels used by <https://github.com/longhorn/longhorn/labels>:

- severity/1
  - Function broken (a critical incident with very high impact (ex: data corruption, failed upgrade)
- severity/2
  - Function working but has a major issue w/o workaround (a major incident with significant impact)
- severity/3
  - Function working but has a major issue w/ workaround
- severity/4
  - Function working but has a minor issue (a minor incident with low impact)

### openSUSE

This is the current severity fields used for openSUSE bugs:
<https://en.opensuse.org/openSUSE:Bug_definitions>

- Blocker
  - Prevents developers or testers from performing their jobs. Impacts the development process
  - (Documentation) Key documentation is missing for critical testing and review
- Critical
  - Crash, loss of data, corruption of data, severe memory leak
  - (Documentation) prescribes or doesn't warn against actions that cause data loss or corruption
- Major
  - Major loss of function, as specified in the product requirements for this release, or existing
  in the current product
  - (Documentation) missing, misleading, inaccurate, or contradictory information to the degree that
  by following the documentation successful completion of fundamental tasks is unlikely
- Normal
  - Regular issue, some non-major loss of functionality under specific circumstances
  - (Documentation) missing, misleading, inaccurate, or contradictory information in the
  documentation, but successful task completion is probable
- Minor
  - Issue that can be viewed as trivial (e.g. cosmetic, UI, easily documented)
  - (Documentation) contains stylistic or formatting issues, but functionality is not hindered

### Outcome

By using a name instead of a number, we wish to make the label very clear for the reporter and for
the team. Also this will help making the distinction between priority and severity (priority/0 and
severity/blocker for instance):

- severity/blocker
  - Prevents developers or testers from performing their jobs. Impacts the development process
- severity/critical
  - Crash, loss of data, corruption of data, severe memory leak, failed upgrade
- severity/major
  - Major loss of function, as specified in the requirements for this release, or existing in the
current product
- severity/normal
  - Regular issue, some non-major loss of functionality under specific circumstances
- severity/trivial
  - Issue that can be viewed as minor (e.g. cosmetic, UI, easily documented)

## Decision Outcome

0005-project-labels.md will have to be modified to include the new labels for severity.
