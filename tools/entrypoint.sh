#!/bin/bash
#
# run-s3gw.sh - wrapper to run a radosgw binary
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

default_id="s3gw"
default_debug_level="none"

rgw_pid=

usage() {
  cat <<EOF
usage: $0 [options... -- args]

options:
  --help                Shows this message.
  --id ID               Specifies a custom instance ID (default: ${default_id}).
  --cert FILE KEY       Specifies SSL certificate. Expects a .crt as first
                        argument, and a .key as second argument.
  --dns-name VALUE      For vhost style buckets, VALUE should be the DNS domain
                        to be used.
  --debug LEVEL         Runs with debug. Levels available: "high", "medium",
                        "low", "none" (default: ${default_debug_level}).
  --no-telemetry        Disable telemetry.
  --telemetry-url URL   Specifies telemetry URL.
  --with-status         Enables status frontend at port 9090.


args:
  Any option supported by RADOS Gateway. For advanced use only.

env variables:
  S3GW_ID                         Specifies a custom instance ID.
  S3GW_DNS_NAME                   Specifies a DNS domain to be used for vhost style
                                  buckets.
  S3GW_DEBUG                      Specifies the debug level to be used.
  S3GW_CERT_FILE                  Specifies the SSL certificate file.
  S3GW_CERT_KEY                   Specifies the SSL certificate key file.

  S3GW_DEFAULT_USER_ID            Specifies the default admin user's ID.
  S3GW_DEFAULT_USER_DISPLAY_NAME  Specifies the default admin user's name.
  S3GW_DEFAULT_USER_EMAIL         Specifies the default admin user's email.
  S3GW_DEFAULT_USER_ACCESS_KEY    Specifies the default admin user's access key.
  S3GW_DEFAULT_USER_SECRET_KEY    Specifies the default admin user's secret key.
  S3GW_DEFAULT_USER_CAPS          Specifies the default admin user's capabilities.
  S3GW_DEFAULT_USER_SYSTEM        Specifies whether the default admin user should be a system user.

  Options always override environment variables.
EOF
}

stop_rgw() {
  kill -n SIGTERM ${rgw_pid}
  exit 1
}

s3gw_id=${S3GW_ID:-${default_id}}
s3gw_debug_level=${S3GW_DEBUG:-${default_debug_level}}
s3gw_dns_name=${S3GW_DNS_NAME:-}

cert_file=${S3GW_CERT_FILE:-}
cert_key=${S3GW_CERT_KEY:-}

with_telemetry=1
telemetry_url=
with_status=0

export RGW_DEFAULT_USER_ID=${S3GW_DEFAULT_USER_ID:-"testid"}
export RGW_DEFAULT_USER_DISPLAY_NAME=${S3GW_DEFAULT_USER_DISPLAY_NAME:-"Admin User"}
export RGW_DEFAULT_USER_EMAIL=${S3GW_DEFAULT_USER_EMAIL:-""}
export RGW_DEFAULT_USER_ACCESS_KEY=${S3GW_DEFAULT_USER_ACCESS_KEY:-"test"}
export RGW_DEFAULT_USER_SECRET_KEY=${S3GW_DEFAULT_USER_SECRET_KEY:-"test"}
export RGW_DEFAULT_USER_CAPS=${S3GW_DEFAULT_USER_CAPS:-"usage=read,write;users=read,write"}
export RGW_DEFAULT_USER_SYSTEM=${S3GW_DEFAULT_USER_SYSTEM:-"0"}

extra_args=()

while [[ $# -gt 0 ]]; do

  case $1 in
  --help)
    usage
    exit 0
    ;;
  --id)
    s3gw_id="${2}"
    shift 1
    ;;
  --dns-name)
    s3gw_dns_name="${2}"
    shift 1
    ;;
  --debug)
    s3gw_debug_level="${2}"
    shift 1
    ;;
  --cert)
    cert_file="${2}"
    cert_key="${3}"
    shift 2
    ;;
  --cert-key)
    cert_key="${2}"
    shift 1
    ;;
  --no-telemetry)
    with_telemetry=0
    ;;
  --telemetry-url)
    telemetry_url="${2}"
    shift 1
    ;;
  --with-status)
    with_status=1
    ;;
  --)
    shift 1
    extra_args=("$@")
    break
    ;;
  *)
    echo "ERROR: unknown argument '${1}'" >/dev/stderr
    exit 1
    ;;
  esac

  shift 1

done

# this can only happen if the user specifies "--id ''".
[[ -z "${s3gw_id}" ]] &&
  echo "ERROR: s3gw ID can't be empty!" >/dev/stderr &&
  exit 1

rgw_debug_value=0

if [[ -n "${s3gw_debug_level}" ]]; then
  case ${s3gw_debug_level} in
  none) ;;
  low)
    rgw_debug_value=1
    ;;
  medium)
    rgw_debug_value=10
    ;;
  high)
    rgw_debug_value=20
    ;;
  *)
    echo "ERROR: unknown debug value '${s3gw_debug_level}'" >/dev/stderr
    exit 1
    ;;
  esac
fi

if [[ -n "${cert_file}" ]]; then
  if [[ -z "${cert_key}" ]]; then
    echo "ERROR: missing SSL certificate key file"
    exit 1
  fi
elif [[ -n "${cert_key}" ]]; then
  echo "ERROR: missing SSL certificate file"
  exit 1
fi

frontend_args="beast port=7480"
if [[ -n "${cert_file}" ]]; then
  [[ ! -f "${cert_file}" ]] &&
    echo "ERROR: certificate file not found at '${cert_file}'" &&
    exit 1

  [[ ! -f "${cert_key}" ]] &&
    echo "ERROR: certificate key file not found at '${cert_key}'" &&
    exit 1

  frontend_args="beast port=7480 ssl_port=7481
    ssl_certificate=${cert_file} ssl_private_key=${cert_key}"
fi

if [[ $with_status -eq 1 ]]; then
  frontend_args+=", status bind=0.0.0.0 port=9090"
fi

args=(
  "--id"
  "${s3gw_id}"
  "--debug-rgw"
  "${rgw_debug_value}"
)

[[ -n "${s3gw_dns_name}" ]] &&
  args=("${args[@]}" "--rgw-dns-name" "${s3gw_dns_name}")

args=("${args[@]}" "${extra_args[@]}")

if [[ $with_telemetry -eq 1 ]]; then
  if [[ -n "${telemetry_url}" ]]; then
    args=(
      "${args[@]}"
      "--rgw-s3gw-telemetry-upgrade-responder-url"
      "${telemetry_url}"
    )
  fi
else
  args=(
    "${args[@]}"
    "--rgw-s3gw-enable-telemetry"
    "false"
  )
fi

trap "stop_rgw" EXIT

radosgw -d \
  --no-mon-config \
  --rgw-data /data/ \
  --run-dir /run/ \
  --rgw-sfs-data-path /data \
  --rgw-backend-store sfs \
  --rgw-frontends "${frontend_args}" \
  "${args[@]}" &

rgw_pid=$!
wait ${rgw_pid}
