# SFS Error Handling

## Context and Problem Statement

### Error Sources

**Filesystem**.
`ENOSPC`, `EIO`, corruption, permissions, write / read / close / open errors.

**SQLite**.
See [SQLite Docs: Result and Error Codes](https://www.sqlite.org/rescode.html) for details.
sqlite_orm makes primary result codes available via `std::system_error`

Critical: `SQLITE_INTERNAL`, `SQLITE_PERM`, `SQLITE_NOMEM`, `SQLITE_READONLY`, `SQLITE_IOERR`, `SQLITE_CORRUPT`, `SQLITE_NOTFOUND`, `SQLITE_FULL`, `SQLITE_CANTOPEN`, `SQLITE_TOOBIG`, `SQLITE_MISMATCH`, `SQLITE_MISUSE`, `SQLITE_NOLFS`, `SQLITE_AUTH`, `SQLITE_RANGE`, `SQLITE_NOTADB`

Not critical (transaction aborts, deadlocks, busy database, constrain violation, etc.): `SQLITE_ABORT`, `SQLITE_BUSY`, `SQLITE_LOCKED`, `SQLITE_INTERRUPT`, `SQLITE_PROTOCOL`, `SQLITE_SCHEMA`, `SQLITE_CONSTRAINT`

**Failed transaction retries**.
We retried a transaction that threw `SQLITE_BUSY` to often

**Requests to non-existing data**.
Bucket, object, version, user does not exists.

**Out of scope**.
Rate limiting, Broken requests (parse failures, etc.)

### Layers

**RGW OPs (this document)**.
Translates RGW error codes to S3/HTTP compatible responses.
We have a generic exception handler that translates exceptions into 500 / Internal Server Error.

**SAL**.
See `rgw_sal.h`.
Errors returned via negative return codes. See `rgw_common.{cc,h}`.

**SFS: SAL Implementation (this document)**.
Where we use SFS SQLite to implement SAL logic.
Examples: Atomic Writer

**SFS: SQLite (this document)**.
Methods and functions that do SQLite queries, transactions.
Examples: `SQLiteVersionedObjects::get_versioned_objects`, `Object::metadata_finish`

**Filesystem**.
Typically `errno` style errors. With STL sometimes exceptions.

**sqlite_orm**.
Throws `std::system_error` with SQLite error code.

## Decision

### RGW OPs Layer

In addition to the regular RGW error handling, we have an exception
handler in place.

Transforms critical errors into shutdowns / crashes. Critical errors
may originate from sqlite_orm or filesystem operations.

Transforms non-critical errors into 500 / Internal Server Error.

Non-critical errors should not bubble up to this handler and are considered a bug.

### SFS: SQLite Layer

Must not throw non-critical errors. Critical errors are OK to bubble up.

Options to return errors:

*boolean returns*, where `true` means *did the thing* and `false` *did not do the thing*.
Useful, when the exact cause isn't important to the layer above.

*negative integer style returns*, where the integer *should* be something unique to SFS.
Should not be a RGW error code, filesystem error, SQLite error, etc.

### SFS: SAL Implementation Layer

Must handle non-critical lower-level errors and return RGW error codes.
May catch and rethrow critical exceptions.

Example:
A failed transaction from SFS SQLite returns false.
The SFS SAL implementation uses that to clean up the request and return a `ERR_INTERNAL_ERROR`.

Important on this layer is, that clients may retry on certain errors before failing a request.
We can leverage this where it is easier / cheaper to let the client retry than us.
