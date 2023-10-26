---
status: proposed
tags: radosgw
updated: 20231026
---

# radosgw development mode

## Context and Problem Statement

For development/testing purposes it could be worth having the ability to enable
a so called: *development mode* in the `radosgw`.
Such mode should obviously be disabled by default and should be explicitly
enabled with a dedicated parameter set by the developer/tester.
When under the *development mode*, the `radosgw` would accept certain kind of requests
otherwise ignored.

Decide on the merits of a single request type is not in the scope of this ADR, here
we want to establish whether the presence of the development mode is admissible
per se.

It follows a list of request categories that could be enabled when the `radosgw`
is under the *development mode*:

- Fault injections
- Artificial slowdowns
- Event dispatching to other development/testing components

The development mode in the `radosgw` could be enabled by a parameter:

```yaml
- name: rgw_dev_mode
  type: bool
  level: dev
  default: false
  desc: enable radosgw development mode
  service:
    - rgw
```
