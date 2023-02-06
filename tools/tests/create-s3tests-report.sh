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
  cat << EOF
usage: $0 LOGFILE <mandatory> [options]

mandatory:
  --branch NAME     Name of aquarist-labs/ceph.git branch.
  --pr ID           Pull Request ID from aquarist-labs/ceph.git.
  --sha STRING      SHA256 of tested commit from tested branch.

  One of --branch or --pr must be specified, but never the two at the
  same time.

options:
  --help|-h         This message
  --user NAME       User generating this report (default: ${USER}).
  --publish         Publish the result to the 's3gw-status' repository.
  --output|-o       Output file

example:
  $ $0 s3gw-s3test-2022-06-03-205212-1ldv/s3gw-s3tests.log \\
      --branch wip-foo \\
      --sha 123aadsfsdf3244 \\
      --user joao

NOTE:

  When using the '--publish' option, a clone of 's3gw-status.git' will be
  required in the same directory from which this script is run. We recommend
  configuring this repository prior to using this option to ensure properly
  signed commits.

EOF
}

res_errors=()
res_fails=()
res_okay=()
resfile=
branch=
prid=
sha=
user=${USER}
publish=false

posargs=()
while [[ $# -gt 0 ]]; do

  case ${1} in
    --help|-h)
      usage
      exit 0
      ;;
    --branch)
      branch="${2}"
      shift 1
      ;;
    --pr)
      prid="${2}"
      shift 1
      ;;
    --sha)
      sha="${2}"
      shift 1
      ;;
    --user)
      user="${2}"
      shift 1
      ;;
    --publish)
      publish=true
      ;;
    --output|-o)
      outfn="${2}"
      shift 1
      ;;
    *)
      posargs=(${posargs[@]} ${1})
      ;;
  esac
  shift 1

done

resfile=${posargs[0]}

if [[ -z "${resfile}" ]]; then
  error "error: results file not provided."
  usage
  exit 1

elif [[ -z "${branch}" && -z "${prid}" ]]; then
  error "error: neither --branch nor --pr specified."
  exit 1

elif [[ -n "${branch}" && -n "${prid}" ]]; then
  error "error: both --branch and --pr specified."
  exit 1

elif [[ -z "${sha}" ]]; then
  error "error: --sha not specified."
  exit 1
fi

if $publish ; then

  if [[ ! -d "s3gw-status.git" ]]; then
    cat <<EOF
error: 's3gw-status.git' repository not found in current directory.

Please ensure a clone is present, and properly configured, before publishing
results.

E.g.,

  $ git clone git@github.com:aquarist-labs/s3gw-status s3gw-status.git
  $ cd s3gw-status.git
  $ git config user.name "Joao Eduardo Luis"
  $ git config user.email "joao@suse.com"
  $ git config user.signingkey joao@suse.com

EOF
    exit 1
  fi
fi

while IFS= read -r line ; do
  [[ -z "${line}" ]] && break
  [[ ! "${line}" =~ .*" ... ".* ]] && continue
  read -r testname testres <<< \
    $(echo "${line}" | sed -n 's/\(.*\) ... \(.*\)/\1 \2/p')

  case ${testres} in
    ok)
      res_okay=(${res_okay[@]} ${testname})
      ;;
    ERROR)
      res_errors=(${res_errors[@]} ${testname})
      ;;
    FAIL)
      res_fails=(${res_fails[@]} ${testname})
      ;;
  esac

done < "${resfile}"

now=$(date -u +"%FT%TZ")
if [ -z "${outfn}" ]; then outfn="s3gw-s3tests-${now}-${user}.json"; fi
cat >>${outfn} <<EOF
{
  "branch": "${branch}",
  "pr": "${prid}",
  "sha": "${sha}",
  "date": "${now}",
  "user": "${user}",
  "results": {
    "success": [
EOF
for ((i=0 ; i < ${#res_okay[@]} ; i++)); do
  comma=","
  [[ $((i+1)) -eq ${#res_okay[@]} ]] && comma=
  cat >>${outfn} <<EOF
      "${res_okay[$i]}"${comma}
EOF
done
cat >>${outfn} <<EOF
    ],
    "failed": [
EOF
for ((i=0 ; i < ${#res_fails[@]} ; i++)); do
  comma=","
  [[ $((i+1)) -eq ${#res_fails[@]} ]] && comma=
  cat >>${outfn} <<EOF
      "${res_fails[$i]}"${comma}
EOF
done
cat >>${outfn} <<EOF
    ],
    "errors": [
EOF
for ((i=0 ; i < ${#res_errors[@]} ; i++)); do
  comma=","
  [[ $((i+1)) -eq ${#res_errors[@]} ]] && comma=
  cat >>${outfn} <<EOF
      "${res_errors[$i]}"${comma}
EOF
done
cat >>${outfn} <<EOF
    ]
  }
}
EOF

echo "wrote report to ${outfn}"

if $publish ; then
  cp ${outfn} s3gw-status.git/results/s3tests/${outfn} || exit 1
  pushd s3gw-status.git || exit 1
  git remote update || exit 1
  git pull origin main || exit 1
  git checkout main || exit 1
  git add results/s3tests/${outfn} || exit 1
  git commit -m "results/s3tests: report ${outfn}" -S -s || exit 1
  git push origin main || exit 1
fi
