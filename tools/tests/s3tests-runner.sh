#!/bin/bash

set -e

CEPH_DIR=${CEPH_DIR:-"/srv/ceph"}
S3GW_CONTAINER=${S3GW_CONTAINER:-"quay.io/s3gw/s3gw:latest"}

OUTPUT_DIR=${OUTPUT_DIR:-"$(pwd)/s3tests.results"}
OUTPUT_FILE=${OUTPUT_FILE:-"${OUTPUT_DIR}/report.json"}

S3TEST_REPO=${S3TEST_REPO:-"$(pwd)"}
S3TEST_CONF=${S3TEST_CONF:-"${CEPH_DIR}/qa/rgw/store/sfs/tests/fixtures/s3tests.conf"}
S3TEST_LIST=${S3TEST_LIST:-"${CEPH_DIR}/qa/rgw/store/sfs/tests/fixtures/s3-tests.txt"}

CONTAINER=
FORCE_CONTAINER=${FORCE_CONTAINER:-"OFF"}
JOB=
TMPFILE=
TMPDIR=


_setup() {
  local test="$1"

  mkdir -p "${OUTPUT_DIR}/logs/${test}"

  if [ ! -d "${CEPH_DIR}/build/bin" ] ; then
    echo "Using s3gw container"
    CONTAINER=$(podman run --rm -d -p 7480:7480 quay.io/s3gw/s3gw:latest)
  elif ! grep -q -i suse /etc/os-release || [ "${FORCE_CONTAINER}" = "ON" ] ; then
    echo "Using runtime container"
    CONTAINER=$(podman run \
      --rm \
      -d \
      -p 7480:7480 \
      -v "${CEPH_DIR}/build/bin":"/radosgw/bin" \
      -v "${CEPH_DIR}/build/lib":"/radosgw/lib" \
      quay.io/s3gw/run-radosgw:latest
    )
  else
    echo "Using host runtime"
    TMPDIR=$(mktemp -q -d -p "${OUTPUT_DIR}" data.XXXXXX.dir)
    mkdir -p "${TMPDIR}/data" "${TMPDIR}/run"

    "${CEPH_DIR}/build/bin/radosgw" \
      -d \
      --no-mon-config \
      --id s3gw \
      --rgw-data "${TMPDIR}/data" \
      --run-dir "${TMPDIR}/run" \
      --rgw-sfs-data-path "${TMPDIR}/data" \
      --rgw-backend-store sfs \
      --debug-rgw 1 \
      > "${OUTPUT_DIR}/logs/${test}/radosgw.log" 2>&1 &
    JOB="$!"

    # sleep until s3gw has spun up
    while ! curl -s localhost:7480 > /dev/null ; do sleep .1 ; done
  fi

  pushd "${S3TEST_REPO}" > /dev/null || exit 1
}


_run() {
  local test="$1"
  local result=
  local name ; name="$(echo "$test" | cut -d ':' -f 2)"

  _setup "$test"

  # this is needed for nosetests
  export S3TEST_CONF
  if nosetests \
      -c "${S3TEST_CONF}" \
      -s \
      -a '!fails_on_rgw,!lifecycle_expiration,!fails_strict_rfc2616' \
      "$test" > "${OUTPUT_DIR}/logs/${test}/test.output" 2>&1 ; then
    result="success"
  else
    result="failure"
  fi

  echo "$test : $result"

  yq -i \
    ".tests += [{\"name\": \"${name}\", \"result\": \"${result}\"}]" \
    "${TMPFILE}"
  _teardown
}


_teardown() {
  if [ -n "$CONTAINER" ] ; then
    podman kill "$CONTAINER"
  else
    kill "$JOB"
    rm -rf "${TMPDIR}"
  fi

  popd > /dev/null || exit 1
}


_convert() {
  yq -o=json '.' "${TMPFILE}" > "${OUTPUT_FILE}"
  rm "${TMPFILE}"
}


_main() {
  [ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"
  [ -d "${OUTPUT_DIR}/logs" ] || mkdir -p "${OUTPUT_DIR}/logs"

  TMPFILE="$(mktemp -q -p "${OUTPUT_DIR}" report.XXXXXX.ymal)"
  [ -f "${TMPFILE}" ] || echo "tests:" > "${TMPFILE}"

  if [ -n "$1" ] ; then
    _run "$1"
  else
    while read -r test ; do
      _run "$test"
    done < <( grep -v '#' "$S3TEST_LIST" )
  fi

  _convert
}


_main "$@"
