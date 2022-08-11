# s3gw Storage Backend

## Context and Problem Statement

How to store RGW data without RADOS? What are our options? How to
work well on Longhorn?

## Decision Drivers

* Performance
* Works well on Longhorn and NVMe
* Versioned buckets
* Efficient copy between buckets
* Efficient large file handling

## Considered Options

RGW SAL backends:

* RGW dbstore. Used in our first MVP release
* Ceph OSD ObjectStore (OS) (FileStore or Blue Store)
* Forked FileStore
* *sfs* - SQLite with custom filesystem store

## Decision Outcome

Chosen option: "sfs", because

* Ceph OS is not a good fit. Transactions are nice, but we don't need
  them and certainly don't want to pay for them.
* RGW dbstore is an option, but storing object data in SQLite fails
  our efficiency and performance requirements

### We don't need transactions

* We can serialize using SQLite if we need to
* We only store immutable data to disk. Since we assume fast storage,
  we can wait for durable fsynced writes.

## Positive Consequences

* We will create knowledge on the data path in the team
* We won't have mutability code paths that we don't need

## Negative Consequences

* We start from scratch. We have to deal with the intricacies of
  storage devices and their failure models.

## Pros and Cons of the Options

### SAL dbstore

SAL dbstore is an upstream WIP project. Everything in SQLite.

### Ceph OSD ObjectStore

Leverage the OSD ObjectStore. The SAL backend would be a translation
layer from RGW objects and buckets to OS collections and objects. The
OS API is transaction based and supports in place updates.

[PoC code](https://github.com/irq0/ceph/tree/wip/rgw-filestore)
PoC uses the OS abstraction, but only supports FileStore not BlueStore.

* Good, because OS is battle tested
* Good, because we don't need to implement our own efficient low level
  file handling and error management code.
* Good, because with filestore we get a hash directory tree
  implementation
* Neutral, because we get transactions
* Neutral, because we could leverage RGW object classes
* Bad, because the OS collection abstractions (PGs, etc) do not fit
  the RGW S3 model

### Forked Filestore

A big problem with the OS approach above was the mismatch in the
collections abstractions. A way around this is to fork filestore and
replace coll_t, hobject_t and the like with our own types.

[PoC Code](https://github.com/irq0/ceph/tree/wip/rgw-filestore-fork)

* Good, because we have the freedom to adjust filestore to our needs
* Neutral, because we no longer follow the upstream filestore progress.
  Filestore is deprecated - This could be a new life as SAL backend.
