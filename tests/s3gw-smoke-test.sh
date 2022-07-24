#!/bin/bash
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

set -x

testpath=$(mktemp -d s3gw.XXXX --tmpdir=/tmp)
s3cfg=${testpath}/s3cfg
url="${1}"

usage() {
  cat << EOF
usage: $0 ADDRESS[:PORT[/LOCATION]]
EOF
}

s3() {
  s3cmd -c ${s3cfg} $*
  return $?
}

[[ -z "${url}" ]] && usage && exit 1

cat > ${s3cfg} << EOF
[default]
access_key = test
secret_key = test
host_base = ${url}/
host_bucket = ${url}/%(bucket)
signurl_use_https = False
use_https = False
signature_v2 = True
signurl_use_https = False
EOF

pushd ${testpath}

# Please note: rgw will refuse bucket names with upper case letters.
# This is due to amazon s3's bucket naming restrictions.
# See:
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
#
bucket="s3gw-test-$(tr -dc a-z0-9 < /dev/urandom | head -c 4)"

s3 ls s3:// || exit 1
s3 mb s3://${bucket} || exit 1
s3 ls s3://${bucket} || exit 1
s3 ls s3://${bucket}-dne && exit 1

dd if=/dev/random bs=1k count=1k of=obj1.bin || exit 1
dd if=/dev/random bs=1k count=2k of=obj2.bin || exit 1

s3 put obj1.bin s3://${bucket}/ || exit 1
s3 put obj1.bin s3://${bucket}/obj1.bin || exit 1
s3 put obj1.bin s3://${bucket}/obj1.bin.2 || exit 1
s3 put obj1.bin s3://${bucket}/my/obj1.bin || exit 1
s3 get s3://${bucket}/obj1.bin obj1.bin.local || exit 1
orig_md5=$(md5sum -b obj1.bin | cut -f1 -d' ')
down_md5=$(md5sum -b obj1.bin.local | cut -f1 -d' ')

[[ "${orig_md5}" == "${down_md5}" ]] || exit 1

s3 get s3://${bucket}/dne.bin && exit 1

must_have=("obj1.bin" "obj1.bin.2" "my/obj1.bin")
ifs_old=$IFS
IFS=$'\n'
lst=($(s3 ls s3://${bucket}))

[[ ${#lst[@]} -eq 3 ]] || exit 1
for what in ${must_have[@]} ; do
  found=false
  for e in ${lst[@]}; do
    r=$(echo $e | grep "s3://${bucket}/${what}$")
    [[ -n "${r}" ]] && found=true && break
  done
  $found || exit 1
done

s3 rm s3://${bucket}/obj1.bin.2 || exit 1

s3 put obj2.bin s3://${bucket}/obj2.bin || exit 1
s3 put obj1.bin s3://${bucket}/obj2.bin || exit 1
s3 get s3://${bucket}/obj2.bin obj2.bin.local || exit 1
md5_before=$(md5sum -b obj2.bin | cut -f1 -d' ')
md5_after=$(md5sum -b obj2.bin.local | cut -f1 -d' ')
md5_expected=$(md5sum -b obj1.bin | cut -f1 -d' ')

[[ "${md5_before}" != "${md5_after}" ]] || exit 1
[[ "${md5_after}" == "${md5_expected}" ]] || exit 1

md5_obj1=$(md5sum -b obj1.bin | cut -f1 -d' ')

do_copy() {
  dst_bucket=$1

  # For now this operation fails. While the copy actually succeeds, s3cmd then
  # tries to perform an ACL operation on the bucket/object, and that fails.
  # We need to ensure the object is there instead, and check it matches in
  # contents.
  s3 cp s3://${bucket}/obj1.bin s3://${dst_bucket}/obj1.bin.copy || true
  s3 get s3://${dst_bucket}/obj1.bin.copy obj1.bin.copy.${dst_bucket} || exit 1

  md5_copy=$(md5sum -b obj1.bin.copy.${dst_bucket} | cut -f1 -d' ')
  [[ "${md5_copy}" == "${md5_obj1}" ]] || exit 1

  if ! s3 ls s3://${dst_bucket} | grep -q obj1.bin.copy ; then
    exit 1
  fi
}

# copy from $bucket/obj to $bucket/obj.copy
do_copy ${bucket}

# copy from $bucket/obj to $newbucket/obj.copy
newbucket="${bucket}-2"
s3 mb s3://${newbucket} || exit 1
do_copy ${newbucket}


exit 0
