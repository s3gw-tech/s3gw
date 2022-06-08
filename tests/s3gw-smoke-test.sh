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

exit 0
