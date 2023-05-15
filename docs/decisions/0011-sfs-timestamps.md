<!-- #cSpell:words multicol datefunc -->
# SFS Timestamps

## Context and Problem Statement

We need to create, handle and persist timestamps.

In the RGW space we have ceph_time.h and std::chrono.

SQLite represents time as ISO-8601, Julian day or unix timestamps.
Stored in TEXT, REAL or INTEGER data types. [SQLite doc:
data types](https://www.sqlite.org/datatype3.html). It has functions to
work with these data types. [SQLite doc:
datefunc](https://www.sqlite.org/lang_datefunc.html).

This doc is about the conversion between RGW/sfs and SQLite space.

Summary of discussion in weeks 19, 20 2023. [GH
Comments](https://github.com/aquarist-labs/s3gw/pull/497)

## Ceph time

We use `ceph::real_time` as timestamps.

`ceph::real_time` is a `uint64_t` nanosecond count since epoch.

## How to store time in SQLite

### Requirements

Minimum microsecond resolution.

We can leverage SQLIte range queries, sorting, indices. Ideally we can
leverage date / time functions with minor conversion.

### Considered Options

Options, that don't fit our requirements:

- *ISO8601* strings. Not enough resolution.
- *UNIX time* - Not enough resolution

- *multicol* - Store seconds as *ISO8601* or *UNIX time* (SQLite
  functions work directly). Store nanoseconds in a second column.
  Queries awkward.
- *int64 ns* - Store as int64, nanosecond resolution, convert from
  uint64. Max value up to year 2262. Queries work.
- *int64 us* - Store as int64, microsecond resolution, convert from
  uint64. Max value up to year 2554. Queries work.
- *hex* - Store as 16 char hex string. Full `ceph::real_time` range.
  Conversion cost. Queries work.
- *uint64* - Squeeze `uint64_t` into SQLite `INTEGER` type
  representation. No queries.
- *blob* - Store `ceph::real_time` as an SQLite blob. Can't query and
  index as easily as *hex* or *int64* options.

### Decision Outcome

We choose *int64 ns*, because it meets all criteria.

It requires minimal conversion. We can live with the year 2262
limitation.
