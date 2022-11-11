# Git branches and tags

## Context and Problem Statement

How are Git branches and tags handled within the project?

## Decision Outcome

- Git branches and tags are named in general according the schema `vN.N.N`
  where `N` means any non-negative integer.
- Main development will be done in the `main` branch.
- Development branches will be named `vN.N.x`, e.g. `v0.8.x`. The development
  of all minor releases will be done in this branch.
- Tags are named `vN.N.N` according to the release, e.g. `v0.8.1`. They will
  be created out of the `vN.N.x` development branches.
