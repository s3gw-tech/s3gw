# Collection of High Level Design Decisions

Use soft deletion. Mark versions deleted, let a garbage collector hard
delete *later*.

Non-versioned objects are a special case of versioned objects. They
generally follow the same logic.

The SFS SQLite database is the source of truth. Example: If we delete
an object, we first modify the database then the filesystem. Example:
Serve metadata (object size, mtime, ..) from the database rather
than stat() the file.

SQLite transactions are atomic. Filesystem operations maybe. Both combined are not.
Orphaned files on the filesystem are acceptable and countered by an offline fsck tool.

Use Ceph bufferlist encodings of data structures in the database where
we don't have to query individual fields. Example: object attrs is
bufferlist encoded, deletion time is not. With this leverage Ceph data
structure versioning support as much as possible.

Use negative return value style error handling not exceptions. This
follows from the Google C++ style guide and the general RGW style.
