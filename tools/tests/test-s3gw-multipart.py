#!/usr/bin/env python3
#
# Copyright 2022 SUSE, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from pathlib import Path
import string
from typing import Any, Dict, List, Tuple
import unittest
import boto3, boto3.s3.transfer
import random
import tempfile
from pydantic import BaseModel
import hashlib

ACCESS_KEY = "test"
SECRET_KEY = "test"
URL = "http://127.0.0.1:7480"

BUCKET_NAME_LEN = 8
OBJECT_NAME_LEN = 10
UPLOAD_ID_LEN = 12


class MultipartPart(BaseModel):
    path: Path
    size: int
    md5: str


class MultipartFile(BaseModel):
    parts: List[MultipartPart]
    object: Path
    md5: str


class MultipartUploadSmokeTests(unittest.TestCase):

    buckets: List[str]

    def setUp(self) -> None:
        self.s3 = boto3.resource(  # type: ignore
            "s3",
            endpoint_url=URL,
            aws_access_key_id=ACCESS_KEY,
            aws_secret_access_key=SECRET_KEY,
        )
        self.s3c = boto3.client(  # type: ignore
            "s3",
            endpoint_url=URL,
            aws_access_key_id=ACCESS_KEY,
            aws_secret_access_key=SECRET_KEY,
        )
        self.testdir = tempfile.TemporaryDirectory()
        self.testpath = Path(self.testdir.name)
        self.buckets = []

    def tearDown(self) -> None:
        # cleanup buckets
        for name in self.buckets:
            bucket = self.s3.Bucket(name)
            bucket.objects.delete()
            bucket.delete()

        self.s3c.close()
        self.s3.meta.client.close()
        self.testdir.cleanup()

    def create_bucket(self) -> str:
        name = self.get_random_bucket_name()
        self.s3c.create_bucket(Bucket=name)
        self.assert_bucket_exists(name)
        assert name not in self.buckets
        self.buckets.append(name)
        return name

    def get_random_name(self, len: int) -> str:
        return "".join(
            random.choice(string.ascii_lowercase) for _ in range(len)
        )

    def get_random_bucket_name(self) -> str:
        return self.get_random_name(BUCKET_NAME_LEN)

    def get_random_object_name(self) -> str:
        return self.get_random_name(OBJECT_NAME_LEN)

    def get_random_upload_id(self) -> str:
        return self.get_random_name(UPLOAD_ID_LEN)

    def gen_multipart(
        self, objname: str, size: int, partsize: int
    ) -> MultipartFile:

        path: Path = self.testpath / objname
        parts_lst: List[MultipartPart] = []

        nparts = int(size / partsize)
        last_part_size = size % partsize
        if last_part_size > 0:
            nparts += 1

        out_full = path.open("wb")
        full_md5 = hashlib.md5()

        for i in range(nparts):
            partfile: Path = Path(f"{path}.part.{i}")
            s = partsize
            if last_part_size > 0 and i == nparts - 1:
                s = last_part_size
            data = os.urandom(s)
            with partfile.open("wb") as out_part:
                out_part.write(data)
                out_full.write(data)
            md5 = hashlib.md5(data)
            full_md5.update(data)
            parts_lst.append(
                MultipartPart(path=partfile, size=s, md5=md5.hexdigest())
            )

        out_full.close()
        return MultipartFile(
            parts=parts_lst, object=path, md5=full_md5.hexdigest()
        )

    def gen_random_file(self, objname: str, size: int) -> Tuple[Path, str]:
        path: Path = self.testpath / objname
        data = os.urandom(size)
        with path.open("wb") as outfd:
            outfd.write(data)
        md5 = hashlib.md5(data)
        return path, md5.hexdigest()

    def assert_bucket_exists(self, name: str) -> None:
        res = self.s3c.list_buckets()
        found = False
        for b in res["Buckets"]:
            if "Name" in b and b["Name"] == name:
                found = True
                break
        self.assertTrue(found)

    def test_dne_upload_multipart(self):
        bucket_name = self.create_bucket()
        objname = self.get_random_object_name()
        upload_id = self.get_random_upload_id()
        upload = self.s3.MultipartUpload(bucket_name, objname, upload_id)
        part = upload.Part(1)  # type: ignore
        has_error = False
        try:
            part.upload(Body=b"foobarbaz")
        except self.s3.meta.client.exceptions.NoSuchUpload:
            has_error = True

        self.assertTrue(has_error)
        self.s3c.delete_bucket(Bucket=bucket_name)
        return

    def test_multipart_upload_download(self):
        bucket_name = self.create_bucket()
        objname = self.get_random_object_name()
        objsize = 100 * 1024**2  # 100 MB
        objpath, md5 = self.gen_random_file(objname, objsize)

        cfg = boto3.s3.transfer.TransferConfig(
            multipart_threshold=10 * 1024,  # 10 MB
            max_concurrency=10,
            multipart_chunksize=10 * 1024**2,  # 10 MB
            use_threads=True,
        )

        obj = self.s3.Object(bucket_name, objname)
        obj.upload_file(objpath.as_posix(), Config=cfg)

        downobj = self.testpath / f"{objname}.down.bin"
        obj.download_file(downobj.as_posix(), Config=cfg)

        with downobj.open("rb") as fd:
            down_md5 = hashlib.md5(fd.read())

        self.assertTrue(down_md5.hexdigest() == md5)

    def test_upload_multipart_manual(self):
        bucket_name = self.create_bucket()
        objname = self.get_random_object_name()
        objsize = 100 * 1024**2  # 100 MB
        partsize = 10 * 1024**2  # 10 MB
        mp = self.gen_multipart(objname, objsize, partsize)
        print(
            f"generated multipart upload, bucket: {bucket_name}, "
            f"obj: {objname}, path: {mp.object}"
        )

        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)

        parts_lst: List[Dict[str, Any]] = []
        upload = self.s3.MultipartUpload(bucket_name, objname, res["UploadId"])
        part_num = 1
        for part_entry in mp.parts:
            part = upload.Part(part_num)  # type: ignore
            sz = part_entry.path.stat().st_size
            print(
                f"upload part {part_num}/{len(mp.parts)}, "
                f"md5: {part_entry.md5}, size: {sz}"
            )
            with part_entry.path.open("rb") as fd:
                res = part.upload(Body=fd.read())
            self.assertTrue("ETag" in res)
            etag = res["ETag"]
            print(f"uploaded part {part_num}/{len(mp.parts)}, etag: {etag}")
            parts_lst.append({"ETag": etag, "PartNumber": part_num})
            part_num += 1

        print(f"parts_lst: {parts_lst}")
        upload.complete(MultipartUpload={"Parts": parts_lst})  # type: ignore

        cfg = boto3.s3.transfer.TransferConfig(
            multipart_threshold=10 * 1024,
            max_concurrency=10,
            multipart_chunksize=10 * 1024**2,
            use_threads=True,
        )
        downobj = self.testpath / f"{objname}.down.bin"
        print(f"download object to {str(downobj)}")

        with downobj.open("wb") as fd:
            self.s3c.download_fileobj(bucket_name, objname, fd, Config=cfg)
        self.assertTrue(downobj.exists())
        self.assertTrue(downobj.is_file())

        with downobj.open("rb") as fd:
            md5 = hashlib.md5(fd.read())

        sz = downobj.stat().st_size
        orig_sz = mp.object.stat().st_size
        print(f"expected md5: {mp.md5}, size: {orig_sz}")
        print(f"     got md5: {md5.hexdigest()}, size: {sz}")
        with mp.object.open("rb") as fd:
            md5_2 = hashlib.md5(fd.read())
            print(f"actual md5: {md5_2.hexdigest()}")
        self.assertTrue(md5.hexdigest() == mp.md5)

    def test_list_ongoing_parts(self):
        bucket_name = self.create_bucket()
        objname = self.get_random_object_name()
        objsize = 100 * 1024**2  # 100 MB
        partsize = 10 * 1024**2  # 10 MB
        mp = self.gen_multipart(objname, objsize, partsize)
        print(
            f"generated multipart upload, bucket: {bucket_name}, "
            f"obj: {objname}, path: {mp.object}"
        )
        self.assertTrue(len(mp.parts) == 10)

        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)
        upload_id = res["UploadId"]

        res = self.s3c.list_parts(
            Bucket=bucket_name, Key=objname, UploadId=upload_id
        )
        if "Parts" in res:
            # the "Parts" entry may or may not be present if the multipart
            # upload has zero parts.
            self.assertTrue(len(res["Parts"]) == 0)

        # upload a part
        upload = self.s3.MultipartUpload(bucket_name, objname, res["UploadId"])
        part = upload.Part(1)  # type: ignore
        part_entry = mp.parts[0]
        part_size = part_entry.path.stat().st_size
        with part_entry.path.open("rb") as fd:
            res = part.upload(Body=fd.read())
        self.assertTrue("ETag" in res)
        etag = res["ETag"]

        # check part is listed
        res = self.s3c.list_parts(
            Bucket=bucket_name, Key=objname, UploadId=upload_id
        )
        self.assertTrue("Parts" in res)
        self.assertTrue(len(res["Parts"]) == 1)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        res_part = res["Parts"][0]
        self.assertTrue(
            "PartNumber" in res_part and res_part["PartNumber"] == 1
        )
        self.assertTrue("ETag" in res_part and res_part["ETag"] == etag)
        self.assertTrue("Size" in res_part and res_part["Size"] == part_size)

    def test_list_multipart_uploads(self):
        bucket_name = self.create_bucket()

        # we need known object names so we can have deterministic results later
        # on when obtaining the multiparts list.
        objname = "aaaa"

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        if "Uploads" in res:
            # "Uploads" may or may not be present if there are zero multipart
            # uploads in progress.
            self.assertTrue(len(res["Uploads"]) == 0)

        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)
        upload_id = res["UploadId"]

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)
        entry = res["Uploads"][0]
        self.assertTrue("UploadId" in entry and entry["UploadId"] == upload_id)

        # what about if we have a limit on the number of uploads returned?
        objname2 = "bbbb"
        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname2)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)
        upload_id2 = res["UploadId"]

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name, MaxUploads=1)
        self.assertTrue("IsTruncated" in res and res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)
        self.assertTrue(
            "NextUploadIdMarker" in res
            and res["NextUploadIdMarker"] == upload_id
        )
        self.assertTrue(
            "NextKeyMarker" in res and res["NextKeyMarker"] == objname
        )
        entry = res["Uploads"][0]
        self.assertTrue("UploadId" in entry and entry["UploadId"] == upload_id)

        res = self.s3c.list_multipart_uploads(
            Bucket=bucket_name, MaxUploads=1, KeyMarker=objname
        )
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)
        self.assertTrue(
            "NextUploadIdMarker" in res
            and res["NextUploadIdMarker"] == upload_id2
        )
        self.assertTrue(
            "NextKeyMarker" in res and res["NextKeyMarker"] == objname2
        )
        entry = res["Uploads"][0]
        self.assertTrue("UploadId" in entry and entry["UploadId"] == upload_id2)

    def test_abort_multipart_upload(self):
        bucket_name = self.create_bucket()

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        if "Uploads" in res:
            # "Uploads" may or may not be present if there are zero multipart
            # uploads in progress.
            self.assertTrue(len(res["Uploads"]) == 0)

        objname = "aaaa"
        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)
        upload_id = res["UploadId"]

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)
        entry = res["Uploads"][0]
        self.assertTrue("UploadId" in entry and entry["UploadId"] == upload_id)

        # doesn't return relevant information
        self.s3c.abort_multipart_upload(
            Bucket=bucket_name, Key=objname, UploadId=upload_id
        )

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        if "Uploads" in res:
            self.assertTrue(len(res["Uploads"]) == 0)

        upload = self.s3.MultipartUpload(bucket_name, objname, upload_id)
        part = upload.Part(1)  # type: ignore
        has_error = False
        try:
            part.upload(Body=f"foobarbaz")
        except self.s3.meta.client.exceptions.NoSuchUpload:
            has_error = True
        self.assertTrue(has_error)

        # XXX: this is likely a bug, we should not have a multipart upload if
        # it was not created via 'create_multipart_upload()', because it was
        # not inited in the backend.
        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)

        res = self.s3c.create_multipart_upload(Bucket=bucket_name, Key=objname)
        self.assertTrue("UploadId" in res)
        self.assertTrue(len(res["UploadId"]) > 0)
        self.assertNotEqual(upload_id, res["UploadId"])
        upload_id2 = res["UploadId"]

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 2)

        # doesn't return relevant information
        self.s3c.abort_multipart_upload(
            Bucket=bucket_name, Key=objname, UploadId=upload_id2
        )

        res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
        self.assertTrue("IsTruncated" in res and not res["IsTruncated"])
        self.assertTrue("Uploads" in res and len(res["Uploads"]) == 1)

        # ensure bucket is removed
        self.s3c.delete_bucket(Bucket=bucket_name)

        # ensure there are no more multiparts for this bucket, which should be
        # the case since we expect the bucket to not exist.
        has_error = False
        try:
            res = self.s3c.list_multipart_uploads(Bucket=bucket_name)
            # we should never reach this point
            print(f"oops! res = {res}")
        except self.s3.meta.client.exceptions.NoSuchBucket:
            has_error = True
        self.assertTrue(has_error)
