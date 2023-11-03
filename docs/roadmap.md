<!-- markdownlint-disable MD024 -->

# Roadmap

All future items in this document are forward-looking statements, and subject to
change. Please don't hesitate in providing us with feedback, may it be on these
items or additional features, so we can consider and prioritize them
accordingly.

## 2024

### Quarter 1

- Better Documentation
- [End-to-End Checksums][epic-e2e-checksums]
- [User Quota][epic-user-quota]

---

### Quarter 2

- Longhorn 1.7 General Availability
- [Temporary access credentials (Secure Token Service)][epic-iam-sts]
- [More Interesting Metrics][epic-metrics]
- [Automation/Scripting of Object Store/Bucket/User][epic-crd-enhancements]
  (Experimental Availability)

---

### Quarter 3

- [S3 SELECT][epic-s3select]

---

### Quarter 4

- Longhorn 1.8 (?)
- [Multi-Site][epic-multi-site] Active/Passive
- [Automation/Scripting of Object Store/Bucket/User][epic-crd-enhancements]
  (General Availability)

---

## 2023

### Quarter 1

- [Expiration Lifecycle Management (unversioned)][2]
- [Object locks][3]
- [Object listing with prefixes/filters][4]
- [Telemetry][5]
- [UI: Object deletion/undeletion][7]

---

### Quarter 2

- [Expiration Lifecycle Management (versioned)][8]
- [Access & Identity Management][10]
- [Metrics from backend][9]
- [UI: Object versioning][11]
- [Crash Consistency][epic-crash-consistency]

---

### Quarter 3

- [COSI Controller][epic-cosi-controller]
- [UI: Backend][epic-ui-backend]
- [Multipart Upload and Copy][epic-multipart]
- [Better Object Listing][epic-object-listing]

---

### Quarter 4

- Longhorn 1.6 Experimental Availability
- [Longhorn Controller][epic-lh-controller]
- [Longhorn UI Integration][epic-lh-ui-integration]
- [Stable On-Disk format][epic-stable-on-disk]
- [Metrics on UI][epic-metrics]

---

## 2022

### Quarter 1

- Brainstorm process

---

### Quarter 2

- Initial project setup
- First tests with RGW
- [UI mockups][1]

---

### Quarter 3

- File-based backend
- Basic S3 operations support
- User management
- Helm charts
- Testing
- UI implementation
- Documentation
- Basic object management & versioning
- Bucket management
- Automation implementation

---

### Quarter 4

- Object deletion/undeletion
- Multipart uploads
- Multipart copy
- ACL support
- UI: Basic object explorer
- Rancher Partner chart

---

### Plan of direction

Features the team wants to develop but are currently not a top priority.

- [Implement Storage classes][14]
- Lambda Functions on S3

### In scope

Features that aren't currently planned but the project would accept external
contributions.

- [SSO][16]

### Out of scope

Features that aren't being considered unless core assumptions change.

- None at the moment

!!! Info
Please note that this roadmap is an evergreen document and will most
certainly evolve as we continue to learn from our users.

[1]: https://www.figma.com/file/qGWXKomwzIUhsDz7QqixAc/S3-Wireframe---Branded?t=PAXtYcfL0tEPLPmm-1
[2]: https://github.com/aquarist-labs/s3gw/issues/215
[3]: https://github.com/aquarist-labs/s3gw/issues/228
[4]: https://github.com/aquarist-labs/s3gw/issues/256
[5]: https://github.com/aquarist-labs/s3gw/issues/202
[7]: https://github.com/aquarist-labs/s3gw/issues/255
[8]: https://github.com/aquarist-labs/s3gw/issues/257
[9]: https://github.com/aquarist-labs/s3gw/issues/258
[10]: https://github.com/aquarist-labs/s3gw/issues/227
[11]: https://github.com/aquarist-labs/s3gw/issues/271
[14]: https://github.com/aquarist-labs/s3gw/issues/230
[16]: https://github.com/aquarist-labs/s3gw/issues/260
[epic-lh-controller]: https://github.com/aquarist-labs/s3gw/issues/470
[epic-lh-ui-integration]: https://github.com/aquarist-labs/s3gw/issues/541
[epic-stable-on-disk]: https://github.com/aquarist-labs/s3gw/issues/428
[epic-multi-site]: https://github.com/aquarist-labs/s3gw/issues/259
[epic-cosi-controller]: https://github.com/aquarist-labs/s3gw/issues/398
[epic-iam-sts]: https://github.com/aquarist-labs/s3gw/issues/229
[epic-ui-backend]: https://github.com/aquarist-labs/s3gw/issues/388
[epic-multipart]: https://github.com/aquarist-labs/s3gw/issues/216
[epic-garbage-collection]: https://github.com/aquarist-labs/s3gw/issues/7
[epic-object-listing]: https://github.com/aquarist-labs/s3gw/issues/256
[epic-crash-consistency]: https://github.com/aquarist-labs/s3gw/issues/362
[epic-e2e-checksums]: https://github.com/aquarist-labs/s3gw/issues/26
[epic-user-quota]: https://github.com/aquarist-labs/s3gw/issues/359
[epic-metrics]: https://github.com/aquarist-labs/s3gw/issues/258
[epic-crd-enhancements]: https://github.com/aquarist-labs/s3gw/issues/629
[epic-s3select]: https://github.com/aquarist-labs/s3gw/issues/791
