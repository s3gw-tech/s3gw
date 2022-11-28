# Git branches and tags

## Context and Problem Statement

How are Git branches and tags handled within the project?

## Decision Outcome

- Main development will be done in the `main` branch.
- Development branches will be named `s3gw-vN.N.x`, e.g. `s3gw-v0.8.x`.
  The development of all minor releases will be done in this branch.
- Git tags will be named `s3gw-vN.N.N` where `N` means any non-negative
  integer, e.g. `s3gw-v0.8.0`.
- Tags will be created out of the `s3gw-vN.N.x` development branches.
