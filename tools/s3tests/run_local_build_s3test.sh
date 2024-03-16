#!/bin/bash
#
# Copyright 2023 SUSE, LLC.
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
#

set -e

OUTPUT_DIR=${OUTPUT_DIR:-"/tmp/s3tests"}
CEPH_BUILD_DIR=${CEPH_BUILD_DIR:-"${CEPH_DIR}/build"}
NPROC=${NPROC:-"$(nproc --ignore=2)"}

_usage() {
  echo "# RUNS ALL S3TESTS AND ANALYSIS"
  echo "CEPH_DIR=/home/user/dev/ceph ${0}"
  echo ""
  echo "# RUNS ONLY test_object_copy_to_itself S3TEST"
  echo "CEPH_DIR=/home/user/dev/ceph ${0} test_object_copy_to_itself"
  echo ""
  echo "# RUNS ALL S3TESTS, CEPH_BUILD_DIR is different to CEPH_DIR/build"
  echo "export CEPH_DIR=/home/user/dev/ceph"
  echo "export CEPH_BUILD_DIR=/home/user/dev/ceph/build_clang"
  echo "${0}"
}

while getopts ":h" o; do
  case "${o}" in
    *)
      _usage
      exit 0
      ;;
  esac
done

if [ -z "$CEPH_DIR" ]
then
  echo "CEPH_DIR environment variable is not set!"
  exit 1
fi

TESTS_PARAMETER="s3tests_boto3/functional/test_s3.py"
if [ "$#" -eq 1 ]
then
  SINGLE_S3_TEST=$1
  echo "Running single test: $SINGLE_S3_TEST"
  TESTS_PARAMETER="s3tests_boto3/functional/test_s3.py::${SINGLE_S3_TEST}"
fi

if [ ! -d "${CEPH_BUILD_DIR}" ]
then
  echo "${CEPH_BUILD_DIR} does not exist"
  exit 1
fi

if [ ! -x "${CEPH_BUILD_DIR}/bin/radosgw" ]
then
  echo "${CEPH_BUILD_DIR}/bin/radosgw was not found or it's not executable"
  echo "Check CEPH_BUILD_DIR is valid and radosgw was built"
  echo "CEPH_BUILD_DIR should be the folder containing the bin and lib folders"
  echo "CEPH_BUIlD_DIR=${CEPH_BUILD_DIR}"
  exit 1
fi

docker run \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${OUTPUT_DIR}":/out  \
  ghcr.io/s3gw-tech/s3tr:latest \
  run \
    --docker-api unix://run/docker.sock \
    --image docker.io/opensuse/tumbleweed:latest \
    --nproc "${NPROC}" \
    --tests "${TESTS_PARAMETER}" \
    --extra-container-args '{
    "volumes": [
      "/usr:/usr:ro",
      "'"${CEPH_BUILD_DIR}"':/compile:ro",
      "/bin:/bin:ro"
	  ],
	  "environment": [
	    "PATH=/compile/bin:/bin:/usr/bin",
	    "LD_LIBRARY_PATH=/compile/lib"
	  ]}' \
  /out/s3tr.json

if [ -z "$SINGLE_S3_TEST" ]
then
  docker run --rm \
    -v "${OUTPUT_DIR}":/out \
    -v "${CEPH_DIR}":/ceph:ro \
      ghcr.io/s3gw-tech/s3tr:latest \
        analyze summary \
        /out/s3tr.json \
	/ceph/qa/rgw/store/sfs/tests/fixtures/s3tr_excuses.csv
else
  jq  -r "first | .test_output" "${OUTPUT_DIR}"/s3tr.json
  echo "============================================================"
  echo "COMMAND TO GET RADOSGW LOGS:"
  echo "jq -r 'first | .container_logs' ${OUTPUT_DIR}/s3tr.json"
  echo "============================================================"
fi
