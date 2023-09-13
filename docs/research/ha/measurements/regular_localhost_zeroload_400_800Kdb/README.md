# Notes

1. 400K measures done with the WAL file zeroed
2. 800K measures done with the WAL file still to be processed (size 32G)

```
giuseppe ➜ ~/developer/s3gw-ha/wd (main ✗) $ du -sh .
35G	

-rw-r--r-- 1 giuseppe giuseppe 798M Sep 12 15:11 s3gw.db
-rw-r--r-- 1 giuseppe giuseppe  64M Sep 12 15:11 s3gw.db-shm
-rw-r--r-- 1 giuseppe giuseppe  32G Sep 12 15:11 s3gw.db-wal
```

after 1 restart

```
giuseppe ➜ ~/developer/s3gw-ha/wd (main ✗) $ du -sh .
2.4G	.

-rw-r--r-- 1 giuseppe giuseppe 798M Sep 12 15:12 s3gw.db
-rw-r--r-- 1 giuseppe giuseppe  32K Sep 12 15:15 s3gw.db-shm
-rw-r--r-- 1 giuseppe giuseppe    0 Sep 12 15:15 s3gw.db-wal
```
