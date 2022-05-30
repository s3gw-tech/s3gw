#!/bin/sh

set -e

IMAGE_NAME=${IMAGE_NAME:-"s3gw-ui"}
UI_DIR=$(realpath ${UI_DIR:-"../../"${IMAGE_NAME}"/"})
CONTAINER_ENGINE=${CONTAINER_ENGINE:-"podman"}

registry=
registry_args=

build_ui_image() {
  echo "Building ${IMAGE_NAME} image ..."
  case ${CONTAINER_ENGINE} in
  podman)
    podman build -t ${IMAGE_NAME} -f ./Dockerfile.${IMAGE_NAME} ${UI_DIR}
    ;;
  docker)
    docker build -t localhost/${IMAGE_NAME} -f ./Dockerfile.${IMAGE_NAME} ${UI_DIR}
    ;;
  esac
}

push_ui_image() {
  if [ -n "${registry}" ]; then
    echo "Pushing ${IMAGE_NAME} image to registry ..."
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

build_ui_image
push_ui_image

exit 0
