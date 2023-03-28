# Pull Requests and Code Review Guide

This is a guide not law.

Use common sense.

Have fun.

## Protocol

 1. Open PR from your personal fork to a aquarist-labs repo.
 2. Assign to yourself. Set related Issue if it exists.
 3. Pick a reviewer. Ideally someone with domain knowledge. Pick more than one if the PR is particularly complex.
 4. Wait for review(s). Give about 2 days. If you haven't heard back after that or the PR is urgent ping reviewer(s).
 5. Discuss, address feedback until ≥ 1 reviewer(s) approve. No active reviewer disapproves.
 6. Merge as soon as your work is approved

## Review Purpose

Improve quality

Catch bugs

Good engineering

Side effects:

- Learning opportunities
- Expose where we as a team have blind spots and more work to do (e.g create issues)

## Pull Request Anatomy

Has a *topic*, *description* and ≥ 1 *commits*.

A PR or commit must not contain changes that are not mentioned in a commit message.
It does what it says it does.

*Topic*
Which feature, bug fix does the PR address?

*Description*
Use the provided template and checklist.
Add issue number if it exists.
Summarize your changes.

*Commits*
Each commit contributes to the PR's topic.
Some exceptions are okay: Refactoring to make follow ups possible/easier. Minor formatting changes.
Individual commits are GPG signed and have a DCO.

## Expectations

### Role: Reviewer

Answer any questions the author has.

Ask questions to understand the how and why.

Provide productive, constructive feedback.

Point out style violations (if not caught by automated system).

Suggest changes to improve code quality.

Optional:

- Run tests locally
- Run benchmarks

### Role: Author

Drive the PR towards a merge.

Incorporate feedback received from reviewers.

Drive the discussion.

Requests the review only after tests and static analysis tools pass in our CI.
Exception: Draft PRs to receive early feedback.

## Suggestions

### How to Do Code Reviews Like a Human Blog Series

- [Michael Lynch: How to Do Code Reviews Like a Human (Part One)](https://mtlynch.io/human-code-reviews-1/)
- [Michael Lynch: How to Do Code Reviews Like a Human (Part Two)](https://mtlynch.io/human-code-reviews-2/)
- [Micheal Lynch: How to Make Your Code Reviewer Fall in Love with You](https://mtlynch.io/code-review-love/)

### Size

As small as possible. As big as necessary.
Should capture a meaningful change.

### Individual Commits

Should have proper messages.

Should tell a story of how the change comes to be.

### Learning Opportunities

If you are uncertain about how you expressed an ideal in code or
like a suggestion on how to improve code readability.
Feel free to ask the reviewer for a suggestion.
