#!/bin/sh

set -e

BUILDER_IMAGE_NAME=${BUILDER_IMAGE_NAME:-"s3gw-ui-builder"}
IMAGE_NAME=${IMAGE_NAME:-"s3gw-ui"}
S3GW_UI_DIR=$(realpath ${S3GW_UI_DIR:-"../../s3gw-ui/"})
S3GW_UI_DIST_DIR=${S3GW_UI_DIST_DIR:-"${S3GW_UI_DIR}/dist/s3gw-ui/"}

force=false
registry=
registry_args=

usage() {
  cat << EOF
usage: $0 CMD [args...]

commands
  builder-image      Create the app builder image.
  app                Build the app.
  app-image          Create the app image.
  help               This message.

options
  --registry URL     The URL of the registry.
  --no-registry-tls  Disable TLS when pushing to registry.

EOF
}

info() {
  echo "INFO: $*" >/dev/stdout
}

error() {
  echo "ERROR: $*" >/dev/stderr
}

build_builder_image() {
  info "Building ${BUILDER_IMAGE_NAME} image ..."
  podman build -t ${BUILDER_IMAGE_NAME} -f ./Dockerfile.app-builder . || exit 1
}

build_app() {
  info "Building ${IMAGE_NAME} app ..."
  if ! podman image exists "${BUILDER_IMAGE_NAME}"; then
    error "Unable to find builder image '${BUILDER_IMAGE_NAME}'. Please run the 'builder-image' command first." && exit 1
  fi
  rm -rf "${S3GW_UI_DIST_DIR}/*"
  podman run -it --replace --name "${BUILDER_IMAGE_NAME}" \
    -v "${S3GW_UI_DIR}":/srv/app \
    ${BUILDER_IMAGE_NAME}
}

build_app_image() {
  if [ ! -e "${S3GW_UI_DIST_DIR}" ]; then
    error "Application dist folder '${S3GW_UI_DIST_DIR}' does not exist. Please run the 'app' command first." && exit 1
  fi

  info "Building ${IMAGE_NAME} image ..."
  podman build -t ${IMAGE_NAME} -f ./Dockerfile.app ${S3GW_UI_DIST_DIR}

  if [ -n "${registry}" ]; then
    info "Pushing ${IMAGE_NAME} image to registry ..."
    podman push ${registry_args} localhost/${IMAGE_NAME} \
      ${registry}/${IMAGE_NAME}
  fi
}

cmd="${1}"

if [ -z "${cmd}" ]; then
  usage && exit 1
fi

if [ "${cmd}" = "help" ]; then
  usage && exit 0
fi

shift 1

while [ $# -ge 1 ]; do
  case ${1} in
    --force)
      force=true
      ;;
    --registry)
      registry=$2
      shift
      ;;
    --no-registry-tls)
      registry_args="--tls-verify=false"
      ;;
    *)
      error "Unknown argument '${1}'"
      exit 1
      ;;
  esac
  shift
done

case ${cmd} in
  builder-image)
    build_builder_image || exit 1
    ;;
  app)
    build_app || exit 1
    ;;
  app-image)
    build_app_image || exit 1
    ;;
  *)
    error "Unknown command '${cmd}'"
    exit 1
    ;;
esac

exit 0
