# S3 API compatibility

The following table represents the support status for current Amazon S3
functional features, and our forward-looking plans for upcoming releases.

|                        | v0.24.0 | v1.0.0 | v1.x.0 |
| ---------------------- | ------- | ------ | ------ |
| GET/PUT/DELETE         | ✅      | ✅     | ✅     |
| Multipart Uploads      | ✅      | ✅     | ✅     |
| Bucket/Object ACLs     | ✅      | ✅     | ✅     |
| Bucket Object Versions | ✅      | ✅     | ✅     |
| Bucket/Object Tagging  | ✅      | ✅     | ✅     |
| Bucket Lifecycle       | ✅      | ✅     | ✅     |
| Object Locking         | 🟨      | ✅     | ✅     |
| Bucket/User Quotas     | ✅      | ✅     | ✅     |
| Server Side Encryption | 🟥      | ✅     | ✅     |
| Bucket Website         | 🟥      | ✅     | ✅     |
| Bucket Notifications   | 🟥      | ✳️     | ✅     |
| Bucket Request Payment | 🟥      | 🟥     | ✳️️    |
| S3 Storage Classes     | 🟥      | 🟥     | ✳️️    |
| Bucket Policy          | 🟥      | 🟥️    | ✳️️    |
| IAM / STS              | 🟥      | 🟥     | ✳️     |
| Bucket Replication     | 🟥      | 🟥     | 🟥     |

✳️ - maybe / 🟥 - not planned / 🟨 - partial support / ✅ - expected support
