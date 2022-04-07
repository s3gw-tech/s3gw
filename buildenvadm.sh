#!/bin/sh

set -e

BASE_IMAGE=${BASE_IMAGE:-"registry.opensuse.org/opensuse/tumbleweed:latest"}
IMAGE_NAME=${IMAGE_NAME:-"s3gw-build-env"}
CEPH_DIR=$(realpath ${CEPH_DIR:-"../ceph/"})
WORKING_DIR=$(pwd)
CCACHE_DIR=

usage() {
	cat <<EOF
Manage the build environment.

Usage:
  $(basename $0) [options] [command]

Available Commands:
  create      Create but do not start the build environment
  remove      Remove the build environment
  start       Start the build environment
  install     Install all dependencies to create the build environment

Options:
  -h, --help  Show this message.

EOF
}

check_deps() {
	if [ ! $(which buildah) ]; then
	  echo 'Unable to find "buildah". Please make sure it is installed.'
	  exit 1
	fi
	if [ ! $(which podman) ]; then
	  echo 'Unable to find "podman". Please make sure it is installed.'
	  exit 1
	fi
}

create() {
	ctr=$(buildah from ${BASE_IMAGE})
	buildah run ${ctr} /bin/sh -c 'zypper -n install bash make nano vim git ccache cmake ninja'
	buildah run ${ctr} /bin/sh -c '
cat <<EOF >> ~/.inputrc
"\C-[OA": history-search-backward
"\C-[[A": history-search-backward
"\C-[OB": history-search-forward
"\C-[[B": history-search-forward
EOF
'
	buildah config --workingdir '/srv/s3gw-core/build/' ${ctr}
	buildah commit --rm ${ctr} ${IMAGE_NAME}
}

remove() {
	podman rm --ignore ${IMAGE_NAME}
	podman image rm ${IMAGE_NAME}
}

start() {
  EXTRA_ARGS=
  if [ -z "${CCACHE_DIR}" ]; then
    if [ -d ~/.ccache/ ]; then
      CCACHE_DIR=~/.ccache/s3gw-core
      mkdir -p ${CCACHE_DIR}
    fi
  fi
  if [ -n "${CCACHE_DIR}" ]; then
    echo "Using CCACHE_DIR=${CCACHE_DIR}"
    EXTRA_ARGS="--volume $(realpath ${CCACHE_DIR}):/root/.ccache/ ${EXTRA_ARGS}"
  fi
	podman run \
	  --interactive \
	  --tty \
	  --replace \
	  --privileged \
	  --volume ${WORKING_DIR}:/srv/s3gw-core/ \
	  --volume ${CEPH_DIR}:/srv/ceph/ \
	  --hostname ${IMAGE_NAME} \
	  --name ${IMAGE_NAME} \
	  ${EXTRA_ARGS} \
	  ${IMAGE_NAME} \
	  /bin/bash
}

install() {
	. /etc/os-release

	case "${ID}" in
	debian|ubuntu)
	  dirname=Debian_${VERSION_ID}
	  [ "${ID}" = "ubuntu" ] && dirname=xUbuntu_${VERSION_ID}
	  echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${dirname}/ /" | sudo tee /etc/apt/sources.list.d/opensuse_devel_kubic_libcontainers_stable.list
	  curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${dirname}/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/opensuse_devel_kubic_libcontainers_stable.gpg > /dev/null
	  sudo apt-get -y update
	  sudo apt-get -y install buildah podman
	  ;;
	opensuse*|suse|sles)
	  sudo zypper -n install buildah podman
	  ;;
	esac
}

while getopts ":?h" option
do
	case ${option} in
	h|help|?)
		usage >&2
		exit 2
		;;
	esac
done

shift $((OPTIND-1))

case $@ in
create)
	check_deps
	create
	;;
remove)
	check_deps
	remove
	;;
start)
	check_deps
	start
	;;
install)
	install
	;;
*)
	usage >&2
	exit 2
	;;
esac

exit 0
