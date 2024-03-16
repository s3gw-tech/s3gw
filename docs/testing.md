# Testing s3gw

In this directory you can find scripts to test `s3gw` in several different
ways. Below is a description of each type of test.

However, note that each test requires an existing gateway running somewhere
accessible by the tests. This may be an `s3gw` container, or a `radosgw` running
from a source repository. It doesn't matter whether these running on the local
machine or on a remote host, as long as they are accessible to the tests.

## Smoke tests

Basic test battery to smoke out errors and potential regressions.

This script takes a mandatory argument in the form
`ADDRESS[:PORT[/LOCATION]]`. For example, `127.0.0.1:7480/s3gw`, where we know
we will be able to find the `radosgw`.

At the moment, these tests mainly rely on `s3cmd`, which requires to be
installed and available in the `PATH`.

## S3 tests

Runs a comprehensive test battery against a running `radosgw`. It relies on
[ceph/s3-tests](https://github.com/ceph/s3-tests), and will clone this
repository for each test run.

This script also takes a mandatory argument in the form `HOST[:PORT]`, which
must be the address where the `radosgw` can be found. `PORT` defaults to
`7480`.

Each run will be kept in a directory of the form `s3gw-s3test-DATE-TESTID`.
The cloned `ceph/s3-tests` repository, as well as logs, will be kept within
this directory.

### Creating reports

Test reports may be generated using the `create-s3tests-report.sh` script.
This script requires the resulting log file from an `s3gw-s3tests.sh` run.

The report is a `json` file containing relevant information about the run, and
is meant to be shared via the
[s3gw-tech/s3gw-status](https://github.com/s3gw-tech/s3gw-status)
repository (see more information on the [project's README
file](https://github.com/s3gw-tech/s3gw-status#readme).)

Check `create-s3tests-report.sh --help` for more information.

## Benchmarking

With tracking our improvement over time in mind, we are benchmarking
`radosgw` with the file based backend `simplefile`.
This allows us to identify potential performance regressions, as
well as understand whether the changes we're making are actually having an
impact, and at the desired scale.

This script relies on [MinIO's warp tool](https://github.com/minio/warp). To
run it will need this tool to be available on the user's `PATH`. That means
having it installed with `go install github.com/minio/warp@latest`, and have
the `GOPATH` (by default it should be `~/go/bin`) in the user's `PATH`.

This script also requires a `HOST[:PORT]` parameter, similarly to the
other tests so that `warp` knows where to find the `radosgw` being benchmarked.

Additionally, this script takes one of three options: `--large`, writing 6000
objects for 10 minutes; `--medium`, writing 1000 objects for 5 minutes; and
`--small` for 50 objects during 1 minute.

The test will run `wrap` 3 times, for object sizes of 1MiB, 10MiB, and 100MiB.

Each time `wrap` is run, a file will be created containing the results of
the benchmark. This file can later on be used to compare results between runs.
For more information, check `warp`'s help.

## Stress testing

For the purpose of stress testing `s3gw`, you can rely on
[fio](https://github.com/axboe/fio).
The tool is equipped with an HTTP client that can also act as an
`S3` client.
You can therefore use the tool to issue concurrent and serial operations against
`s3gw`.
For a basic stress testing activity you should normally want to shot a series
of `PUT`(s), `GET`(s) and `DELETE`(s).
Such workload can be modeled with a fio _jobfile_.
For example, you can customize the following _jobfile_ and tuning it to realize
the test you wish to perform.

```ini
[global]
ioengine=http
filename=/foo/obj
http_verbose=0
https=off
http_mode=s3
http_s3_key=test
http_s3_keyid=test
http_host=localhost:7480

[s3-write]
numjobs=4
rw=write
size=16m
bs=16m

[s3-read]
numjobs=4
rw=read
size=16m
bs=16m

[s3-trim]
stonewall
numjobs=1
rw=trim
size=16m
bs=16m
```

Once you have created your _jobfile_: `s3gw.fio` you can launch
the workload with:

```shell
$ fio s3gw.fio
Starting 9 processes

...
```

This _jobfile_ connects to an S3 gateway listening on `localhost:7480`
and operates on a object `obj` which resides inside an existing `foo` bucket.
This example launches 3 types of jobs: `s3-write` (PUT), `s3-read`
(GET) and `s3-trim` (DELETE); the actual operation verb is defined by `rw`
property. The actual number of processes performing the same operation is
controlled by `numjobs` property.
`global` section is inherited from all defined jobs.

For this specific example the I/O activity is defined by: `size=16m bs=16m`
meaning that, a 16mb file will be `write`, `read` and `trim` with a single
16mb weighting I/O operation. As result of this, supposing that no `trim`
job has been defined, you would find in the bucket a 16mb object:

```shell
$ s3cmd ls s3://foo
2022-07-19 13:14     16777216  s3://foo/obj_0_16777216
```

By modifying the `bs` property to the value of `4m`, you are diminishing
the weight of a single I/O operation over an overall `16m` size.
As result of this, you would find 4 (16mb/4mb) single objects in the bucket:

```shell
$ s3cmd ls s3://foo
2022-07-19 13:21      4194304  s3://foo/obj_0_4194304
2022-07-19 13:21      4194304  s3://foo/obj_12582912_4194304
2022-07-19 13:21      4194304  s3://foo/obj_4194304_4194304
2022-07-19 13:21      4194304  s3://foo/obj_8388608_4194304
```

To build more complex `fio` workloads, refer to the
[documentation](https://fio.readthedocs.io/en/latest/index.html).
