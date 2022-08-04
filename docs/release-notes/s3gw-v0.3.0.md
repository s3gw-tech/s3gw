# Release Notes - v0.3.0

With v0.3.0 a few things changed in the overall project:

- the `s3gw-core` repository has been renamed `s3gw-tools`;
- the main repository is now [s3gw][1];
- the `s3gw` repository contains documentation and all other s3gw-related
  projects as submodules.

We are also releasing containers for `s3gw` and `s3gw-ui` with this version.
Read below for more information.

**This release is meant for testing and feedback gathering. It is not
recommended for production use.**

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our [github repository][1].

## s3gw

### What we support

At the moment we support creating buckets, doing basic operations on objects
(PUT/GET/DELETE), and listing bucket contents.

### What we don't support

- deleting buckets.
- multipart uploads.
- everything else not specified in the previous section.

### What Changed

**This version introduces a new on-disk format for s3gw. Previous deployments
will not work and will need to be redeployed.**

#### Added

- rgw/sfs: new on-disk format, based on filesystem hash tree for data
  and sqlite for metadata.
- rgw/sfs: maintain one single sqlite database connection.
- rgw/sfs: protect sqlite access with 'std::shared_lock'; allows multiple
  parallel reads, but only one write at a time.
- rgw/sfs: allow copying objects; the current implementation breaks S3
  semantics by returning EEXIST if the destination object exists.

#### Known Issues

- object copy fails if the destination object exists; this will be addressed at
  a later stage.

#### Changed

- rgw/sfs: no longer create directory hierarchy when initing the store; instead,
  ensure the sfs path exists by creating its directory if missing.

#### Removed

- rgw/sfs: remove unused data and metadata functions, artifacts from our
  previous file-based implementation.

## s3gw-ui

The UI has seen several improvements and fixes.

## Deploying

Please refer to our [documentation][2] on how to start playing with the s3gw.
For Helm chart fans, information can be found [here][3].

[1]: https://github.com/aquarist-labs/s3gw
[2]: https://github.com/aquarist-labs/s3gw#quickstart
[3]: https://github.com/aquarist-labs/s3gw-charts#install
