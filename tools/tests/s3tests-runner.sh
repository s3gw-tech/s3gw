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
# - - -
#
# s3tests Runner
#
# This script is a helper for running s3tests against the s3gw/radosgw and
# collecting results and logs. One of the main features of this script is that
# it manages a fresh instance of radosgw for each test, ensuring that crashing
# or corrupting the gateway during one test does not affect the result of the
# next test(s). In addition to that it collects logs both from the s3tests as
# well as the logs from the radosgw instance and compiles a json file describing
# the results of each test.


set -e

[[ -z "$DEBUG" ]] || set -x

CEPH_DIR=${CEPH_DIR:-"/srv/ceph"}
S3GW_CONTAINER=${S3GW_CONTAINER:-"quay.io/s3gw/s3gw:latest"}

OUTPUT_DIR=${OUTPUT_DIR:-"$(pwd)/s3tests.results"}
OUTPUT_FILE=${OUTPUT_FILE:-"${OUTPUT_DIR}/report.json"}

S3TEST_REPO=${S3TEST_REPO:-"$(pwd)"}
S3TEST_CONF=${S3TEST_CONF:-"${CEPH_DIR}/qa/rgw/store/sfs/tests/fixtures/s3tests.conf"}
S3TEST_LIST=${S3TEST_LIST:-"${CEPH_DIR}/qa/rgw/store/sfs/tests/fixtures/s3-tests.txt"}
S3TEST_PARALLEL=${S3TEST_PARALLEL:-"OFF"}
S3TEST_TIMEOUT=${S3TEST_TIMEOUT:-"3m"}

DEFAULT_S3GW_CONTAINER_CMD=${DEFAULT_S3GW_CONTAINER_CMD:-"--rgw-backend-store sfs --debug-rgw 1"}

FORCE_CONTAINER=${FORCE_CONTAINER:-"OFF"}
FORCE_DOCKER=${FORCE_DOCKER:-"OFF"}

S3TEST_LIFECYCLE=${S3TEST_LIFECYCLE:-"ON"}
S3TEST_LIFECYCLE_INTERVAL=${S3TEST_LIFECYCLE_INTERVAL:-"10"}

CONTAINER=
JOB=
TMPDIR=

NPROC=${NPROC:-"$(nproc --ignore=2)"}  # Used to run tests in parallel

CONTAINER_CMD=
CONTAINER_CMD_LOG_OPTS=()

LIFE_CYCLE_INTERVAL_PARAM=
CONTAINER_EXTRA_PARAMS=

# if running in a github worker, the home directory can't be accessed, so the
# configuration must be stored elsewhere.
PARALLEL_HOME=${PARALLEL_HOME:-"${GITHUB_WORKSPACE:-"$HOME"}/.parallel"}


_configure() {
  if [ ! "$FORCE_DOCKER" == "ON" ] && command -v podman ; then
    CONTAINER_CMD=podman
    CONTAINER_CMD_LOG_OPTS=(
      "--log-opt"
      "path=${OUTPUT_DIR}/logs/radosgw.log"
    )
  elif command -v docker ; then
    CONTAINER_CMD=docker
    CONTAINER_CMD_LOG_OPTS=(
      "--log-driver"
      "local"
    )
  else
    exit 2
  fi

  if [ "$S3TEST_LIFECYCLE" == "ON" ] ; then
    LIFE_CYCLE_INTERVAL_PARAM="--rgw-lc-debug-interval ${S3TEST_LIFECYCLE_INTERVAL}"
    CONTAINER_EXTRA_PARAMS="${DEFAULT_S3GW_CONTAINER_CMD} ${LIFE_CYCLE_INTERVAL_PARAM}"
  fi
}


_setup() {
  local slot="$1"
  local test="$2"

  local port=$(( 7480 + slot ))
  TMPDIR="${OUTPUT_DIR}/${test}.tmp"
  mkdir -p "$TMPDIR"

  sed -e "s/^port.*/port = $port/g" "$S3TEST_CONF" > "${TMPDIR}/s3tests.conf"

  mkdir -p "${OUTPUT_DIR}/logs/${test}"

  # sleep until the port is not used by another daemon
  for _ in {1..60} ; do
    if ! nc -z localhost "$port" > /dev/null ; then
      break
    fi
    sleep .1
  done

  if [ ! -d "${CEPH_DIR}/build/bin" ] ; then
    CONTAINER=$("$CONTAINER_CMD" run \
      -d \
      -p "$port":7480 \
      "${CONTAINER_CMD_LOG_OPTS[@]}" \
      "$S3GW_CONTAINER" \
      ${CONTAINER_EXTRA_PARAMS}
    )
  elif [ "${FORCE_CONTAINER}" = "ON" ] ; then
    CONTAINER=$("$CONTAINER_CMD" run \
      -d \
      -p "$port":7480 \
      -v "${CEPH_DIR}/build/bin":"/radosgw/bin" \
      -v "${CEPH_DIR}/build/lib":"/radosgw/lib" \
      "${CONTAINER_CMD_LOG_OPTS[@]}" \
      quay.io/s3gw/run-radosgw:latest \
      ${CONTAINER_EXTRA_PARAMS}
    )
  else
    echo "Using host runtime with port $port"
    mkdir -p "${TMPDIR}/data" "${TMPDIR}/run"

    "${CEPH_DIR}/build/bin/radosgw" \
      -d \
      --no-mon-config \
      --id s3gw \
      --rgw-data "${TMPDIR}/data" \
      --run-dir "${TMPDIR}/run" \
      --rgw-sfs-data-path "${TMPDIR}/data" \
      --rgw-backend-store sfs \
      --rgw_frontends "beast port=$port" \
      --rgw-lc-debug-interval 10 \
      --debug-rgw 1 \
      ${LIFE_CYCLE_INTERVAL_PARAM} \
      > "${OUTPUT_DIR}/logs/${test}/radosgw.log" 2>&1 &
    JOB="$!"

  fi

  # sleep until s3gw has spun up or at most 1 minute
  for _ in {1..600} ; do
    if curl -s "localhost:$port" > /dev/null ; then
      break
    fi
    sleep .1
  done

  pushd "${S3TEST_REPO}" > /dev/null || exit 1
}


_run() {
  local slot="$1"
  local test="$2"

  local result=
  local name ; name="$(echo "$test" | cut -d ':' -f 2)"

  _setup "$slot" "$test"

  starttime=$(date "+%s.N")

  export S3TEST_CONF="${TMPDIR}/s3tests.conf"
  export S3_USE_SIGV4=ON
  if timeout "${S3TEST_TIMEOUT}" pytest \
    "s3tests_boto3/functional/test_s3.py::${name}" \
    > "${OUTPUT_DIR}/logs/${test}/test.output" 2>&1 ; then
    result="success"
  else
    if [ "$?" = "124" ] ; then
      result="timeout"
    else
      result="failure"
    fi
  fi
  endtime=$(date "+%s.%N")
  runtime=$(echo "${endtime} - ${starttime}" | bc)

  _teardown "$slot" "$test" "$result" "$runtime"
}


_teardown() {
  local slot="$1"
  local test="$2"
  local result="$3"
  local runtime="$4"

  echo "$test : $result"

  if [ "$CONTAINER_CMD" = "docker" ] ; then
    docker logs "$CONTAINER" > "${OUTPUT_DIR}/logs/${test}/radosgw.log" 2>&1
  elif [ -n "$CONTAINER" ] ; then
    mv "${OUTPUT_DIR}/logs/radosgw.log" "${OUTPUT_DIR}/logs/${test}/radosgw.log"
  fi

  # set +e
  # IFS= read -rd '' radosgwlog < <(cat "${OUTPUT_DIR}/logs/${test}/radosgw.log")
  # IFS= read -rd '' s3testlog < <(cat "${OUTPUT_DIR}/logs/${test}/test.output")
  # set -e
  touch "${OUTPUT_DIR}/${test}.yaml"

  export name
  export result
  export slot
  export runtime
  export radosgwlog
  export s3testlog
  yq -i \
    ".tests += [{ \"name\": strenv(name), \
                  \"result\": strenv(result), \
                  \"slot\": strenv(slot), \
                  \"time\": strenv(runtime) \
                }]" \
    "${OUTPUT_DIR}/${test}.yaml"
                  # \"s3gw_log\": strenv(radosgwlog), \
                  # \"s3test_log\": strenv(s3testlog) \

  if [ -n "$CONTAINER" ] ; then
    set +e
    "$CONTAINER_CMD" kill "$CONTAINER" > /dev/null 2>&1
    "$CONTAINER_CMD" rm "$CONTAINER" > /dev/null 2>&1
    CONTAINER=
    set -e
  else
    kill "$JOB"
  fi

  rm -rf "${TMPDIR}"
  popd > /dev/null || exit 1
}


_convert() {
  TMPFILE="$(mktemp -q -p "$(pwd)" report.XXXXXX.yaml)"
  [ -f "${TMPFILE}" ] || echo "tests:" > "${TMPFILE}"

  for file in "${OUTPUT_DIR}"/*.yaml ; do
    yq -i ".tests += [$(yq .tests[] "$file" -ojson)]" "${TMPFILE}"
  done

  yq -o=json '.' "${TMPFILE}" > "${OUTPUT_FILE}"
  rm "${TMPFILE}"

  jq ".date |=\"$(date +%Y-%m-%d)\"" "${OUTPUT_FILE}"
  jq ".time |=\"$(date +%H:%M:%S)\"" "${OUTPUT_FILE}"
  jq ".user |= \"$(git config --get user.name)\"" "${OUTPUT_FILE}"
  jq ".git_ref |= \"$(cd "${CEPH_DIR}" ; git rev-parse HEAD)\"" "${OUTPUT_FILE}"
}


_list_results_by_type() {
  local type="$1"

  jq -r \
    ".tests[] | select( .result == \"$type\" ) | .name" \
    "${OUTPUT_FILE}"
}

_count_results_by_type() {
  local type="$1"

  _list_results_by_type "$type" | wc -l
}

_show_failure_logs() {
  while read -r test ; do
    echo "logs for: $test"
    echo "s3gw logs:"
    cat "${OUTPUT_DIR}/logs/${test}/radosgw.log"
    echo "s3test logs"
    cat "${OUTPUT_DIR}/logs/${test}/test.output"
  done < <(_list_results_by_type "failure")
}

# return 0 if there are no failed tests, return 1 otherwise
_has_failed_tests() {
  [ -z "$(jq \
    ".tests[] | select( .result == \"failure\" ) | .name" \
    "${OUTPUT_FILE}")" ]
}


_main() {
  _configure
  [ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"
  [ -d "${OUTPUT_DIR}/logs" ] || mkdir -p "${OUTPUT_DIR}/logs"

  if [ -n "$1" ] ; then
    _run 1 "$1"
  else
    export -f _setup
    export -f _run
    export -f _teardown
    export S3GW_CONTAINER
    export S3TEST_CONF
    export S3TEST_REPO
    export S3TEST_TIMEOUT
    export FORCE_CONTAINER
    export FORCE_DOCKER
    export CONTAINER_CMD
    export CONTAINER_CMD_LOG_OPTS
    export OUTPUT_DIR
    export PARALLEL_HOME
    export CONTAINER_EXTRA_PARAMS
    export LIFE_CYCLE_INTERVAL_PARAM

    if [ "${S3TEST_PARALLEL}" = "ON" ] ; then
      mkdir -p "$PARALLEL_HOME"
      parallel --record-env
      grep -v '#' "$S3TEST_LIST" | parallel --env _ -j "${NPROC}" "_run {%} {}"
    else
      while read -r test ; do
        # run in a subshell to avoid poisoning the environment
        ( _run "1" "$test" )
      done < <( grep -v '#' "$S3TEST_LIST" )
    fi
  fi

  _convert

  _show_failure_logs
  echo "$(_count_results_by_type "success") Successful Tests:"
  _list_results_by_type "success"
  echo "$(_count_results_by_type "failure") Failed Tests:"
  _list_results_by_type "failure"

  _has_failed_tests
}


_main "$@"
