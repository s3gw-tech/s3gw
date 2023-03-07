#!/bin/bash
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
#
# ------
#
# This script performs tests to ensure that no unintended breaking changes are
# introduced to the on-disk format of the s3gw.
# It works by spinning up an old version of the s3gw, uploading a couple objects
# to it, then reusing that volume with a new version of the s3gw, trying to read
# those objects again and ensuring integrity with checksums along the way.

[ -z "$DEBUG" ] || set -x

CEPH_DIR=${CEPH_DIR:-"$PWD/ceph"}
OLD_VERSION=${OLD_VERSION:-"latest"}
NEW_VERSION=${NEW_VERSION:-""}

S3GW_HOST=${S3GW_HOST:-"127.0.0.1:7480"}

VOL=$(mktemp -q -d s3gw.XXXX --tmpdir="$PWD")
SRC=$(mktemp -q -d src.XXXX --tmpdir="$PWD")
DST=$(mktemp -q -d dst.XXX --tmpdir="$PWD")
CFG="$PWD/s3cfg"

CONTAINER=
PODMAN=

_podman() {
  "$PODMAN" "$@"
}

s3() {
  s3cmd -q -c "$CFG" "$@"
}

start_s3gw() {
  local version="$1"

  if [ -n "$version" ] ; then
    echo "Running s3gw ${version}"
    CONTAINER=$(_podman run \
                  --rm -d \
                  -v "${VOL}:/data" \
                  -p 7480:7480 \
                  "quay.io/s3gw/s3gw:${version}")
  else
    echo "Running s3gw from ${CEPH_DIR}/build/bin"
    echo "Contents of bin dir: ----------------"
    ls -la ${CEPH_DIR}/build/bin
    echo "Contents of lib dir: ----------------"
    ls -la ${CEPH_DIR}/build/lib
    echo "Vol is: ${VOL}"
    #_podman run --rm -v "${VOL}:/data" -v "${CEPH_DIR}/build/bin:/radosgw/bin" -v "${CEPH_DIR}/build/lib:/radosgw/lib" -p 7480:7480 quay.io/s3gw/run-radosgw --rgw-backend-store sfs --debug-rgw 1
    CONTAINER=$(_podman run \
                  --rm -d \
                  -v "${VOL}:/data" \
                  -v "${CEPH_DIR}/build/bin:/radosgw/bin" \
                  -v "${CEPH_DIR}/build/lib:/radosgw/lib" \
                  -p 7480:7480 \
                  quay.io/s3gw/run-radosgw \
                    --rgw-backend-store sfs \
                    --debug-rgw 1)
  fi

  echo "Container ${CONTAINER} started"
  for _ in {1..600} ; do
    if curl -s "$S3GW_HOST" > /dev/null ; then
      echo "S3gw is up"
      break
    fi
    sleep .1
  done
  _podman ps -a
  _podman logs ${CONTAINER}
}

stop_s3gw() {
  echo "Stopping s3gw..."
  _podman ps
  _podman kill "$CONTAINER"
  echo "S3gw should be stopped"
  _podman ps
}

setup() {
  echo "Setting up..."

  if command -v podman ; then
    PODMAN=podman
  elif command -v docker ; then
    PODMAN=docker
  else
    exit 1
  fi

  cat > "$CFG" <<EOF
[default]
access_key = test
secret_key = test
host_base = ${S3GW_HOST}/
host_bucket = ${S3GW_HOST}/%(bucket)
signurl_use_https = False
use_https = False
signature_v2 = True
signurl_use_https = False
EOF

  for i in {1..100} ; do
    dd if=/dev/random bs=1k count=5k of="${SRC}/obj-${i}.bin" status=none
  done

  start_s3gw "$OLD_VERSION"
  s3 mb "s3://bucket"
  s3 put "${SRC}"/* "s3://bucket/"
  stop_s3gw

  start_s3gw "$NEW_VERSION"
}

sha256sums() {
  local workdir="$1"
  pushd "$workdir" > /dev/null || exit 1
  sha256sum ./* > checksums
  popd > /dev/null || exit 1
}

trap cleanup EXIT
cleanup() {
  stop_s3gw
  echo "Cleaning up..."
  rm -rf "$VOL"
  rm -rf "$SRC"
  rm -rf "$DST"
  rm -rf "$CFG"
}


test_put_more_objects() {
  echo "putting more objects...."
  _podman ps
  for i in {101..200} ; do
    dd if=/dev/random bs=1k count=5k of="${SRC}/obj-${i}.bin" status=none
  done

  s3 put "${SRC}"/obj-{101..200}.bin "s3://bucket/"
}

test_get_objects() {
  s3 get "s3://bucket/*" "${DST}/"
}

setup

test_put_more_objects
test_get_objects

sha256sums "$SRC"
sha256sums "$DST"

diff "${SRC}/checksums" "${DST}/checksums"
