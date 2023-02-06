#!/bin/sh

set -e

IMAGE_NAME=${IMAGE_NAME:-"s3gw-test"}
CEPH_DIR=$(realpath ${CEPH_DIR:-"../../ceph/"})
CONTAINER_ENGINE=${CONTAINER_ENGINE:-"podman"}

registry=
registry_args=

build_test_container_image() {
  echo "Building test container image ..."

  case ${CONTAINER_ENGINE} in
  podman)
    podman build -t ${IMAGE_NAME} -f ./Dockerfile.build-radosgw-test-container ${CEPH_DIR}/build
    ;;
  docker)
    docker build -t localhost/${IMAGE_NAME} -f ./Dockerfile.build-radosgw-test-container ${CEPH_DIR}/build
    ;;
  esac
}

push_test_container_image() {
  if [ -n "${registry}" ]; then
    echo "Pushing test container image to registry ..."
    ${CONTAINER_ENGINE} push ${registry_args} localhost/${IMAGE_NAME} \
      ${registry}/${IMAGE_NAME}
  fi
}

while [ $# -ge 1 ]; do
  case $1 in
    --registry)
      registry=$2
      shift
      ;;
    --no-registry-tls)
      registry_args="--tls-verify=false"
      ;;
  esac
  shift
done

build_test_container_image
push_test_container_image

exit 0
