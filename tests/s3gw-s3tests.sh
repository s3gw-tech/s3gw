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

error() {
  echo $* >/dev/stderr
}

usage() {
  cat >/dev/stderr <<EOF
usage: $0 HOST[:PORT]
EOF
}

hostport=(${1//:/ })
host=${hostport[0]}
port=${hostport[1]:-7480}

if [[ -z "${host}" || -z "${port}" ]]; then
  usage
  exit 1
fi

testdate="$(date -u +%F-%H%M%S)"
testid="$(tr -dc a-z0-9 < /dev/urandom | head -c 4)"
testdir="s3gw-s3test-${testdate}-${testid}"

mkdir ${testdir} || exit 1
pushd ${testdir} || exit 1

cat > s3test.conf <<EOF
[DEFAULT]
host = ${host}
port = ${port}
is_secure = False
ssl_verify = False

[fixtures]
bucket prefix = s3gwtest-{random}-

[s3 main]
display_name = M. Tester
user_id = testid
email = tester@ceph.com
api_name = default
access_key = test
secret_key = test

[s3 alt]
display_name = john.doe
email = john.doe@example.com
user_id = testid
access_key = test
secret_key = test 

[s3 tenant]
display_name = testx$tenanteduser
user_id = testid
access_key = test 
secret_key = test 
email = tenanteduser@example.com

[iam]
email = s3@example.com
user_id = testid
access_key = test 
secret_key = test 
display_name = youruseridhere
EOF

git clone -b ceph-master https://github.com/ceph/s3-tests s3-tests.git || \
  exit 1
pushd s3-tests.git || exit 1

python3 -m venv venv || exit 1
source venv/bin/activate
pip install -r requirements.txt || exit 1

( S3TEST_CONF=../s3test.conf nosetests -v -s \
  -a '!fails_on_rgw,!lifecycle_expiration,!fails_strict_rfc2616' \
  s3tests_boto3.functional |& tee ../s3gw-s3tests.log ) || exit 1

exit 0
