# Testing s3gw

In this directory one can find scripts to test `s3gw` in several different
ways. Below is a description of each type of test.

However, please note a commonality between the various tests: they require an
existing gateway running somewhere accessible by the tests. This may be an
`s3gw` container, or a `radosgw` running from a source repository. It doesn't
matter whether these running on the local machine or on a remote host, as long
as they are accessible to the tests.


## smoke tests

Basic test battery to smoke out errors and potential regressions.

This script takes a mandatory argument in the form
`ADDRESS[:PORT[/LOCATION]]`. For example, `127.0.0.1:7480/s3gw`, where we know
we will be able to find the `radosgw`.

At the moment, these tests mainly rely on `s3cmd`, which requires to be
installed and available in the `PATH`.

## s3tests

Runs a comprehensive test battery against a running `radosgw`. It relies on
[ceph/s3-tests](https://github.com/ceph/s3-tests), and will clone this
repository for each test run.

This script also takes a mandatory argument in the form `HOST[:PORT]`, which
must be the address where the `radosgw` can be found. `PORT` defaults to
`7480`.

Each run will be kept in a directory of the form `s3gw-s3test-DATE-TESTID`.
The cloned `ceph/s3-tests` repository, as well as logs, will be kept within
this directory.

### creating reports

Test reports may be generated using the `create-s3tests-report.sh` script.
This script requires the resulting log file from an `s3gw-s3tests.sh` run.

The report is a `json` file containing relevant information about the run, and
is meant to be shared via the
[aquarist-labs/s3gw-status](https://github.com/aquarist-labs/s3gw-status)
repository (see more information on the [project's README
file](https://github.com/aquarist-labs/s3gw-status#readme).)

Please check `create-s3tests-report.sh --help` for more information.

## benchmarking

With tracking our improvement over time in mind, we should be benchmarking
`radosgw` with the file based backend `simplefile` we have been developing.
This will allow us to identify early on potential performance regressions, as
well as understand whether the changes we're making are actually having an
impact, and at the desired scale.

This script relies on [MinIO's warp tool](https://github.com/minio/warp). To
run it will need this tool to be available on the user's `PATH`. That means
having it installed with `go install github.com/minio/warp@latest`, and have
the `GOPATH` (by default it should be `~/go/bin`) in the user's `PATH`.

Again, this script will require a `HOST[:PORT]` parameter, similarly to the
other tests, so `warp` knows where to find the `radosgw` being benchmarked.

Additionally, this script takes one of three options: `--large`, writing 6000
objects for 10 minutes; `--medium`, writing 1000 objects for 5 minutes; and
`--small` for 50 objects during 1 minute.

The test will run `wrap` 3 times, for object sizes of 1MiB, 10MiB, and 100MiB.

Each time `wrap` is run, a file will be created containing the results of
the benchmark. This file can later on be used to compare results between runs.
For more information, please check `warp`'s help.


