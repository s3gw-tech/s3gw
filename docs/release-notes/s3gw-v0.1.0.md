# Release Notes - v0.1.0

This is the first publicly available iteration of the s3gw project. Bugs are to
be expected (and welcomed!), and performance is not optimal.

**This release is meant for testing and feedback gathering. It is not
recommended for production use.**

Should a bug be found and not expected to be related to the list below, one
should feel encouraged to file an issue in our [github repository][1].

## What we support

At the moment we support creating buckets, doing basic operations on objects
(PUT/GET/DELETE), and listing bucket contents.

## What we don't support

- deleting buckets.
- multipart uploads.
- everything else not specified in the previous section.

## Deploying

Please refer to our [documentation][2] on how to start playing with the s3gw
container. For Helm chart fans, information can be found [here][3].

[1]: https://github.com/aquarist-labs/s3gw-core
[2]: https://github.com/aquarist-labs/s3gw-core#quickstart
[3]: https://github.com/aquarist-labs/s3gw-charts#install
