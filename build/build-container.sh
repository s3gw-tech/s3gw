#!/bin/sh

set -e

BASE_IMAGE=${BASE_IMAGE:-"registry.opensuse.org/opensuse/tumbleweed:latest"}
IMAGE_NAME=${IMAGE_NAME:-"s3gw"}
CEPH_DIR=$(realpath ${CEPH_DIR:-"../../ceph/"})
INSTALL_PACKAGES=${INSTALL_PACKAGES:-"libblkid1 libexpat1 libtcmalloc4 libfmt8 libibverbs1 librdmacm1 liboath0 libicu71"}
CONTAINER_ENGINE=${CONTAINER_ENGINE:-"podman"}

registry=
registry_args=

check_deps() {
	if [ ! $(which buildah) ]; then
	  echo 'Unable to find "buildah". Please make sure it is installed.'
	  exit 1
	fi
}

build_container_image() {
  echo "Building container image ..."
  echo "BASE_IMAGE=${BASE_IMAGE}"
  echo "IMAGE_NAME=${IMAGE_NAME}"
  echo "CEPH_DIR=${CEPH_DIR}"
  echo "CONTAINER_ENGINE=${CONTAINER_ENGINE}"

  case ${CONTAINER_ENGINE} in
    podman)

  tmpfile=$(mktemp)
  cat > ${tmpfile} << EOF
ctr=\$(buildah from ${BASE_IMAGE})
buildah run \${ctr} /bin/sh -c 'zypper -n install ${INSTALL_PACKAGES}'
mnt=\$(buildah mount \${ctr})
mkdir -p \${mnt}/data/
cp --verbose ${CEPH_DIR}/build/bin/radosgw \${mnt}/usr/bin/radosgw
cp --verbose --no-dereference ${CEPH_DIR}/build/lib/*.so* \${mnt}/usr/lib64/
buildah unmount \${ctr}
buildah config --port 7480 \${ctr}
buildah config --volume /data/ \${ctr}
buildah config --env ID=s3gw \${ctr}
buildah config --cmd '[]' \${ctr}
buildah config --entrypoint '["radosgw", "-d", "--no-mon-config", "--rgw-backend-store", "dbstore", "--id", "\${ID}", "--rgw-data", "/data/", "--run-dir", "/run/"]' \${ctr}
buildah commit --rm \${ctr} ${IMAGE_NAME}
EOF
  buildah unshare sh ${tmpfile}
  rm -f ${tmpfile}

  if [ -n "${registry}" ]; then
    buildah push ${registry_args} localhost/${IMAGE_NAME} \
      ${registry}/${IMAGE_NAME}
  fi
      ;;
    docker)
    docker build -t localhost/${IMAGE_NAME} -f ./Dockerfile.build-container ${CEPH_DIR}/build
      ;;
  esac
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

check_deps
build_container_image

exit 0
