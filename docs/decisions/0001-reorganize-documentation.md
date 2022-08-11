---
status: proposed
---

# Reorganize Documentation

## The documentation may be hard to navigate from an outside perspective

The structure of the documentation may be hard to navigate for someone
unfamiliar with the project.
In particular, the following points stick out:

- The top level order should be:
  - quick start
  - detailed installation and operation instructions
  - detailed technical information for developers
  - how to contribute
  - about & license
- Some subsections should be moved:
  - using the helm chart belongs in installation/operations, not development
  - build instructions (including those for the containers) belong in the
    development section
  - operating the gateway on longhorn belongs in installation/operations
  - roadmap possibly and decision records definitively belong with the technical
    information for developers
- The development section should be ordered such that it's easy for newcomers
  - first subsection should describe general architectural information
  - second subsection should describe the build instructions
  - third subsection should describe testing

## Considered Options

### Not reorganizing

- It's hard to intuitively locate detailed installation instructions as they are
  currently filed under 'Developing the s3gw'
- Technical decisions are stored in their own section, not with the other
  technical documentation. Meaning that there are two possible places to find
  technical information in
- Just reading the table of contents gives the impression that developing the
  s3gw is the most important thing one can do with it, as detailed installation
  instructions are in the fourth section, after developer and build instructions
- Contribution instructions are buried within other sections, making it just a
  bit less convenient to find them

### Reorganizing

- The most important information for a new user is 'how do I use this thing',
  so the installation and operation instructions should be the first section
  after 'Welcome & Quickstart'
- All technical information in one place (the development section), including
  build instructions
- Entry bar for contributions (bugreport/issues are contributions too) is as low
  as possible, with the information on how to contribute being well visible and
  quickly reachable at the top level
- MADR and decisions are not a top level item, but filed away neatly in the
  developer documentation

## Decision Outcome
