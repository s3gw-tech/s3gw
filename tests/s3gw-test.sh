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

img="s3gw:latest"


error() {
  echo "error: $*" >/dev/stderr
}


usage() {

  cat <<EOF
usage: $0 cmd [options]

commands:
  smoke       Run smoke tests.
  s3tests     Run a battery of S3 tests.
  bench       Run a benchmark.
  help        This message.

options:
  --image NAME[:TAG]    Specify which image to use (default: ${img}).
EOF
}


running=false

run_container() {

  [[ -z "${img}" ]] && \
    error "image not specified" && exit 1

  podman run -d -p 7480:7480 --replace --name test-s3gw ${img} || exit 1

  running=true
}

stop_container() {
  if $running ; then
    podman stop test-s3gw || exit 1
  fi
}


trap stop_container EXIT


run_smoke_tests() {
  run_container || exit 1

  ./s3gw-smoke-test.sh 127.0.0.1:7480 || exit 1
}


run_s3tests() {
  run_container || exit 1
  ./s3gw-s3tests.sh 127.0.0.1:7480 || exit 1
}


run_benchmark() {
  run_container || exit 1
  ./s3gw-bench.sh 127.0.0.1:7480 || exit 1
}


posargs=()

while [[ $# -gt 0 ]]; do

  case $1 in
    --image)
      img="$2"
      shift 1
      ;;
    --*)
      error "unknown option '${1}'"
      exit 1
      ;;
    *)
      posargs=(${posargs[@]} $1)
      ;;
  esac
  shift 1
done


cmd=${posargs[0]}
[[ -z "${cmd}" ]] && \
  error "missing command" && \
  usage && exit 1

case ${cmd} in
  smoke)
    run_smoke_tests || exit 1
    ;;
  s3tests)
    run_s3tests || exit 1
    ;;
  bench)
    run_benchmark || exit 1
    ;;
  help)
    usage
    exit 0
    ;;
  *)
    error "unknown command '${cmd}'"
    exit 1
    ;;
esac

