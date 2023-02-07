#!/bin/bash
# build.sh - helper to build container s3gw-related images
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


cephdir=${S3GW_CEPH_DIR:-"../../ceph.git"}
ccachedir=${S3GW_CCACHE_DIR:-""}
build_image_name=${S3GW_BUILD_IMAGE_NAME:-"s3gw-builder"}
build_image=${S3GW_BUILD_IMAGE:-"${build_image_name}:latest"}
s3gw_image=${S3GW_IMAGE:-"s3gw"}
with_tests=${WITH_TESTS:-"OFF"}
build_test_image_name=${S3GW_TEST_BUILD_IMAGE_NAME:-"s3gw-test-builder"}
build_test_image=${S3GW_TEST_BUILD_IMAGE:-"${build_test_image_name}:latest"}
s3gw_test_image=${S3GW_TEST_IMAGE:-"s3gw-test"}

force=false


usage() {
  cat << EOF
usage: $0 CMD [args...]

commands
  build-image       Create the radosgw build image.
  radosgw           Build radosgw.
  s3gw              Create an s3gw container image.
  s3gw-test         Create an s3gw-test container image.
  help              This message.

options
  --ceph PATH       Specifies the Ceph source directory.
                    (default: ${cephdir})
  --ccache PATH     Specifies the ccache directory.
                    (default: ${ccachedir})
  --force           Forces building even if image exists.

env variables
  S3GW_CEPH_DIR                 Specifies the Ceph source directory.
  S3GW_CCACHE_DIR               Specifies the ccache directory.
  S3GW_BUILD_IMAGE_NAME         Specifies the build image name.
  S3GW_BUILD_IMAGE              Specifies the build image (name:tag).
  S3GW_IMAGE                    Specifies the s3gw container image name.
  WITH_TESTS                    Specifies whether build the s3gw test images too.
  S3GW_TEST_BUILD_IMAGE_NAME    Specifies the test build image name.
  S3GW_TEST_BUILD_IMAGE         Specifies the test build image (name:tag).
  S3GW_TEST_IMAGE               Specifies the s3gw test container image name.

EOF
}

error() {
  echo "error: $*" >/dev/stderr
}

build_builder_image() {

  ver=$(git rev-parse --short HEAD)
  img="${build_image_name}:${ver}"

  # check whether this builder image exists
  #
  found=false
  ifs=$IFS
  IFS=$'\n'
  for l in $(podman image list --format '{{.Repository}}:{{.Tag}}'); do
    IFS=" " a=(${l//\// })
    if [[ "${a[1]}" == "${img}" ]]; then
      found=true
    fi
  done
  IFS=$ifs

  if $found && ! $force ; then
    echo "builder image already exists: ${img}"
    return 0
  fi

  podman build -t ${img} -f Dockerfile.build-radosgw . || exit 1
  podman tag ${img} ${build_image_name}:latest
}

build_radosgw() {

  # check build image exists
  #
  found=false
  ifs=$IFS
  IFS=$'\n'
  for l in $(podman image list --format '{{.Repository}}:{{.Tag}}'); do
    IFS=" " a=(${l//\// })
    if [[ "${a[1]}" == "${build_image}" ]]; then
      found=true
    fi
  done
  IFS=$ifs

  ! $found && \
    error "unable to find builder image '${build_image}'" && exit 1

  # check ceph source directory
  #
  [[ -z "${cephdir}" ]] && \
    error "missing ceph directory" && exit 1
  [[ ! -d "${cephdir}" ]] && \
    error "path at '${cephdir}' is not a directory" && exit 1
  [[ ! -d "${cephdir}/.git" ]] && \
    error "path at '${cephdir}' is not a repository" && exit 1

  volumes=("-v ${cephdir}:/srv/ceph")

  # check ccache directory
  #
  if [[ -n "${ccachedir}" ]]; then
    if [[ ! -e "${ccachedir}" ]]; then
      echo "ccache directory at '${ccachedir}' not found; creating."
      mkdir -p ${ccachedir}
    fi
    [[ ! -d "${ccachedir}" ]] && \
      error "ccache path at '${ccachedir}' is not a directory." && exit 1

    volumes=(${volumes[@]} "-v ${ccachedir}:/srv/ccache")
  fi

  podman run -it --replace --name s3gw-builder \
    -e SFS_CCACHE_DIR=/srv/ccache \
    -e WITH_TESTS=${with_tests} \
    ${volumes[@]} \
    ${build_image}
}

build_s3gw() {

  [[ -z "${cephdir}" ]] && \
    error "missing ceph directory" && exit 1
  [[ ! -d "${cephdir}" ]] && \
    error "path at '${cephdir}' is not a directory" && exit 1
  [[ ! -d "${cephdir}/.git" ]] && \
    error "path at '${cephdir}' is not a repository" && exit 1
  [[ ! -d "${cephdir}/build" ]] && \
    error "unable to find build directory at '${cephdir}'" && exit 1
  [[ ! -e "${cephdir}/build/bin/radosgw" ]] && \
    error "unable to find radosgw binary at '${cephdir}' build directory" && \
    exit 1

  ver=$(git --git-dir ${cephdir}/.git rev-parse --short HEAD)
  imgname="${s3gw_image}:${ver}"

  echo "ceph dir: ${cephdir}"
  echo "   image: ${imgname}"

  is_done=false

  ifs=$IFS
  IFS=$'\n'
  for l in $(podman image list --format '{{.Repository}}:{{.Tag}}'); do
    IFS=" " a=(${l//\// })
    if [[ "${a[1]}" == "${imgname}" ]] && ! $force ; then
      echo "found built image '${l}', mark it latest"
      podman tag ${l} s3gw:latest || exit 1
      is_done=true
      break
    fi
  done
  IFS=${ifs}

  if $is_done ; then
    return 0
  fi

  podman build -t ${imgname} \
    -f $(pwd)/Dockerfile.build-container \
    ${cephdir}/build || exit 1
  podman tag ${imgname} s3gw:latest || exit 1
}

build_s3gw_test() {

  [[ -z "${cephdir}" ]] && \
    error "missing ceph directory" && exit 1
  [[ ! -d "${cephdir}" ]] && \
    error "path at '${cephdir}' is not a directory" && exit 1
  [[ ! -d "${cephdir}/.git" ]] && \
    error "path at '${cephdir}' is not a repository" && exit 1
  [[ ! -d "${cephdir}/build" ]] && \
    error "unable to find build directory at '${cephdir}'" && exit 1
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_sqlite_users" ]] && \
    error "unable to find unittest_rgw_sfs_sqlite_users binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_sqlite_buckets" ]] && \
    error "unable to find unittest_rgw_sfs_sqlite_buckets binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_sqlite_objects" ]] && \
    error "unable to find unittest_rgw_sfs_sqlite_objects binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_sqlite_versioned_objects" ]] && \
    error "unable to find unittest_rgw_sfs_sqlite_versioned_objects binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_sfs_bucket" ]] && \
    error "unable to find unittest_rgw_sfs_sfs_bucket binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_metadata_compatibility" ]] && \
    error "unable to find unittest_rgw_sfs_metadata_compatibility binary at '${cephdir}' build directory" && \
  [[ ! -e "${cephdir}/build/bin/unittest_rgw_sfs_gc" ]] && \
    error "unable to find unittest_rgw_sfs_gc binary at '${cephdir}' build directory" && \
    exit 1

  ver=$(git --git-dir ${cephdir}/.git rev-parse --short HEAD)
  imgname="${s3gw_test_image}:${ver}"

  echo "ceph dir: ${cephdir}"
  echo "   image: ${imgname}"

  is_done=false

  ifs=$IFS
  IFS=$'\n'
  for l in $(podman image list --format '{{.Repository}}:{{.Tag}}'); do
    IFS=" " a=(${l//\// })
    if [[ "${a[1]}" == "${imgname}" ]] && ! $force ; then
      echo "found built image '${l}', mark it latest"
      podman tag ${l} s3gw-test:latest || exit 1
      is_done=true
      break
    fi
  done
  IFS=${ifs}

  if $is_done ; then
    return 0
  fi

  podman build -t ${imgname} \
    -f $(pwd)/Dockerfile.build-radosgw-test-container \
    ${cephdir}/build || exit 1
  podman tag ${imgname} s3gw-test:latest || exit 1
}

cmd="${1}"
shift 1

[[ -z "${cmd}" ]] && \
  usage && exit 1

if [[ "${cmd}" == "help" ]]; then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --ceph)
      cephdir="${2}"
      shift 1
      ;;
    --ccache)
      ccachedir="${2}"
      shift 1
      ;;
    --force)
      force=true
      ;;
    *)
      error "unknown argument '${1}'"
      exit 1
      ;;
  esac
  shift 1
done

case ${cmd} in
  build-image)
    build_builder_image || exit 1
    ;;
  radosgw)
    build_radosgw || exit 1
    ;;
  s3gw)
    build_s3gw || exit 1
    ;;
  s3gw-test)
    build_s3gw_test || exit 1
    ;;
  *)
    error "unknown command '${cmd}'"
    exit 1
    ;;
esac
