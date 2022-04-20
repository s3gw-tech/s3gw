#!/bin/sh

set -e

export IMAGE_NAME=${IMAGE_NAME:-"generic/ubuntu2004"}
export VM_NET=${VM_NET:-"10.46.201"}
export VM_NET_LAST_OCTET_START=${CLUSTER_NET_LAST_OCTET_START:-"101"}
export WORKER_COUNT=${WORKER_COUNT:-"1"}

build_env() {
  echo "Building environment ..."
  echo "IMAGE_NAME=${IMAGE_NAME}"
  echo "VM_NET=${VM_NET}"
  echo "VM_NET_LAST_OCTET_START=${VM_NET_LAST_OCTET_START}"
  echo "WORKER_COUNT=${WORKER_COUNT}"
   
  vagrant up
}

destroy_env() {
  echo "Destroying environment ..."
  echo "IMAGE_NAME=${IMAGE_NAME}"
  echo "VM_NET=${VM_NET}"
  echo "VM_NET_LAST_OCTET_START=${VM_NET_LAST_OCTET_START}"
  echo "WORKER_COUNT=${WORKER_COUNT}"
   
  vagrant destroy -f
}

ssh_vm() {
  echo "Connecting to $1 ..."
   
  vagrant ssh $1
}

if [ $# -eq 0 ]; then
  build_env
elif [ $# -eq 1 ]; then
  case $1 in
    build)
      build_env
      break
      ;;
    destroy)
      destroy_env
      break
      ;;
  esac
else
  case $1 in
    ssh)
      ssh_vm $2
      break
      ;;
  esac
fi

exit 0
