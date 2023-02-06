#!/bin/sh

set -e

export BOX_NAME=${BOX_NAME:-"opensuse/Leap-15.3.x86_64"}
export VM_PROVIDER=${VM_PROVIDER:-"libvirt"}
export VM_NET=${VM_NET:-"10.46.201.0"}
export VM_NET_LAST_OCTET_START=${CLUSTER_NET_LAST_OCTET_START:-"101"}
export VM_BRIDGE_INET=${VM_BRIDGE_INET:-"eth0"}
export ADMIN_COUNT=${ADMIN_COUNT:-"1"}
export WORKER_COUNT=${WORKER_COUNT:-"1"}
export ADMIN_MEM=${ADMIN_MEM:-"4096"}
export ADMIN_CPU=${ADMIN_CPU:-"2"}
export ADMIN_DISK=${ADMIN_DISK:-"no"}
export ADMIN_DISK_SIZE=${ADMIN_DISK_SIZE:-"8G"}
export WORKER_MEM=${WORKER_MEM:-"4096"}
export WORKER_CPU=${WORKER_CPU:-"2"}
export WORKER_DISK=${WORKER_DISK:-"no"}
export WORKER_DISK_SIZE=${WORKER_DISK_SIZE:-"8G"}
export CONTAINER_ENGINE=${CONTAINER_ENGINE:-"podman"}
export STOP_AFTER_BOOTSTRAP=${STOP_AFTER_BOOTSTRAP:-"no"}
export STOP_AFTER_K3S_INSTALL=${STOP_AFTER_K3S_INSTALL:-"no"}
export S3GW_IMAGE=${S3GW_IMAGE:-"ghcr.io/aquarist-labs/s3gw:latest"}
export S3GW_IMAGE_PULL_POLICY=${S3GW_IMAGE_PULL_POLICY:-"Always"}
export PROV_USER=${PROV_USER:-"vagrant"}

#these defaults will change
export S3GW_UI_REPO=${S3GW_UI_REPO:-"https://github.com/aquarist-labs/aws-s3-explorer.git"}
export S3GW_UI_VERSION=${S3GW_UI_VERSION:-"s3gw-ui-testing"}

export SCENARIO=${SCENARIO:-"default"}
export K3S_VERSION=${K3S_VERSION:-"v1.23.6+k3s1"}

start_env() {
  echo "Starting environment ..."
  echo "WORKER_COUNT=${WORKER_COUNT}"
  vagrant up
}

build_env() {
  echo "BOX_NAME=${BOX_NAME}"
  echo "VM_PROVIDER=${VM_PROVIDER}"
  echo "VM_NET=${VM_NET}"
  echo "VM_NET_LAST_OCTET_START=${VM_NET_LAST_OCTET_START}"
  echo "VM_BRIDGE_INET=${VM_BRIDGE_INET}"
  echo "ADMIN_COUNT=${ADMIN_COUNT}"
  echo "WORKER_COUNT=${WORKER_COUNT}"
  echo "ADMIN_MEM=${ADMIN_MEM}"
  echo "ADMIN_CPU=${ADMIN_CPU}"
  echo "ADMIN_DISK=${ADMIN_DISK}"
  echo "ADMIN_DISK_SIZE=${ADMIN_DISK_SIZE}"
  echo "WORKER_MEM=${WORKER_MEM}"
  echo "WORKER_CPU=${WORKER_CPU}"
  echo "WORKER_DISK=${WORKER_DISK}"
  echo "WORKER_DISK_SIZE=${WORKER_DISK_SIZE}"
  echo "CONTAINER_ENGINE=${CONTAINER_ENGINE}"
  echo "STOP_AFTER_BOOTSTRAP=${STOP_AFTER_BOOTSTRAP}"
  echo "STOP_AFTER_K3S_INSTALL=${STOP_AFTER_K3S_INSTALL}"
  echo "S3GW_IMAGE=${S3GW_IMAGE}"
  echo "S3GW_IMAGE_PULL_POLICY=${S3GW_IMAGE_PULL_POLICY}"
  echo "PROV_USER=${PROV_USER}"
  echo "S3GW_UI_REPO=${S3GW_UI_REPO}"
  echo "S3GW_UI_VERSION=${S3GW_UI_VERSION}"
  echo "SCENARIO=${SCENARIO}"
  echo "K3S_VERSION=${K3S_VERSION}"

  echo "Building environment ..."
  vagrant up --provision
  echo "Built"

  echo "Cleaning ..."
  rm -rf ./*.tar
  echo "Cleaned"
  echo
  echo "Connect to admin node with:"
  echo "vagrant ssh admin-1"
}

destroy_env() {
  echo "Destroying environment ..."
  echo "WORKER_COUNT=${WORKER_COUNT}"
  vagrant destroy -f
}

ssh_vm() {
  echo "Connecting to $1 ..."
  echo "WORKER_COUNT=${WORKER_COUNT}"

  vagrant ssh $1
}

if [ $# -eq 0 ]; then
  build_env
elif [ $# -eq 1 ]; then
  case $1 in
    start)
      start_env
      ;;
    build)
      build_env
      ;;
    destroy)
      destroy_env
      ;;
  esac
else
  case $1 in
    ssh)
      ssh_vm $2
      ;;
  esac
fi

exit 0
