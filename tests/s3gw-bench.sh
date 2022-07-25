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

gopath=${GOPATH:-${HOME}/go/bin}

error() {
  echo $* >/dev/stderr
}

usage() {
  cat >/dev/stderr <<EOF
usage: $0 HOST[:PORT] [options]

options:
  --large         Run a large test.
  --medium        Run a medium test.
  --small         Run a small test.

  --outdir PATH   Directory to write results to.
  --desc DESC     Specify a short description of this test.
EOF
}

if [[ ! -d "${gopath}" ]]; then
  error "error: unable to find go binary path at '${gopath}'"
  exit 1
fi

warpcmd="${gopath}/warp"
if [[ ! -e "${warpcmd}" ]]; then
  error "error: unable to find 'warp' at '${gopath}'"
  error "consider installing with 'go install github.com/minio/warp@latest'"
  exit 1
fi

duration="1m"
objects=50
test_type="small"
outdir="s3gw-bench-results"
desc=

pos_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --large)
      duration="10m"
      objects=6000
      test_type="large"
      ;;
    --medium)
      duration="5m"
      objects=1000
      test_type="medium"
      ;;
    --small)
      duration="1m"
      objects=50
      test_type="small"
      ;;
    --outdir)
      outdir="$2"
      shift 1
      ;;
    --desc)
      desc="$2"
      shift 1
      ;;
    *)
      pos=(${pos[@]} $1)
      ;;
  esac
  shift 1
done

url="${pos[0]}"
if [[ -z "${url}" ]]; then
  usage
  exit 1
fi

[[ -z "${outdir}" ]] && \
  error "error: please specify a valid output directory" && \
  exit 1

[[ -e "${outdir}" ]] && [[ ! -d "${outdir}" ]] && \
  error "error: '${outdir}' is not a directory" && \
  exit 1

[[ ! -e "${outdir}" ]] && ( mkdir ${outdir} || exit 1 )


cat >/dev/stderr <<EOF
Running ${test_type} test with
  duration: ${duration}
   objects: ${objects}
EOF

run_test() {

  objsize="${1}"
  if [[ -z "${objsize}" ]]; then
    error "error: missing object size for test run"
    exit 1
  fi

  testdate="$(date -u +%F[%H%M%S])"
  testid="$(tr -dc a-z0-9 < /dev/urandom | head -c 4)"
  testbucket="s3gw-bench-${testid}"
  testfn="s3gw-bench"
  [[ -n "${desc}" ]] && testfn="${testfn}-${desc}"
  testfn="${testfn}-${test_type}-${testdate}-${testid}-${objsize}"
  testout="${outdir}/${testfn}"

  ${warpcmd} mixed --host ${url} \
    --access-key test --secret-key test \
    --benchdata ${testout} \
    --obj.size ${objsize} --objects ${objects} \
    --duration ${duration} \
    --noclear \
    --bucket ${testbucket}
  return $?
}

run_test 1MiB || exit 1
run_test 10MiB || exit 1
# run_test 100MiB || exit 1
