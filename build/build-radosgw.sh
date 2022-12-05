#!/bin/bash

set -e

# https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html
# Release: Your typical release build with no debugging information and full optimization.
# MinSizeRel: A special Release build optimized for size rather than speed.
# RelWithDebInfo: Same as Release, but with debugging information.
# Debug: Usually a classic debug build including debugging information, no optimization etc.
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

CEPH_DIR=$(realpath "${CEPH_DIR:-"/srv/ceph"}")
S3GW_CCACHE_DIR=${S3GW_CCACHE_DIR:-"${CEPH_DIR}/build.ccache"}
S3GW_BUILD_DIR="${CEPH_DIR}/build"

WITH_JAEGER=${WITH_JAEGER:-"OFF"}
WITH_LTTNG=${WITH_LTTNG:-"OFF"}
WITH_MANPAGE=${WITH_MANPAGE:-"OFF"}
WITH_OPENLDAP=${WITH_OPENLDAP:-"OFF"}
WITH_RADOSGW_AMQP_ENDPOINT=${WITH_RADOSGW_AMQP_ENDPOINT:-"OFF"}
WITH_RADOSGW_DBSTORE=${WITH_RADOSGW_DBSTORE:-"OFF"}
WITH_RADOSGW_KAFKA_ENDPOINT=${WITH_RADOSGW_KAFKA_ENDPOINT:-"OFF"}
WITH_RADOSGW_LUA_PACKAGES=${WITH_RADOSGW_LUA_PACKAGES:-"OFF"}
WITH_RADOSGW_MOTR=${WITH_RADOSGW_MOTR:-"OFF"}
WITH_RADOSGW_SELECT_PARQUET=${WITH_RADOSGW_SELECT_PARQUET:-"OFF"}
WITH_RDMA=${WITH_RDMA:-"OFF"}
WITH_SYSTEM_BOOST=${WITH_SYSTEM_BOOST:-"ON"}
WITH_TESTS=${WITH_TESTS:-"OFF"}

NPROC=${NPROC:-$(nproc --ignore=2)}

CEPH_CMAKE_ARGS=(
  "-DWITH_CCACHE=ON"
  "-DBOOST_J=${NPROC}"
  "-DCMAKE_C_COMPILER=gcc-11"
  "-DCMAKE_CXX_COMPILER=g++-11"
  "-DENABLE_GIT_VERSION=ON"
  "-DWITH_PYTHON3=3"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DWITH_JAEGER=${WITH_JAEGER}"
  "-DWITH_LTTNG=${WITH_LTTNG}"
  "-DWITH_MANPAGE=${WITH_MANPAGE}"
  "-DWITH_OPENLDAP=${WITH_OPENLDAP}"
  "-DWITH_RADOSGW_AMQP_ENDPOINT=${WITH_RADOSGW_AMQP_ENDPOINT}"
  "-DWITH_RADOSGW_DBSTORE=${WITH_RADOSGW_DBSTORE}"
  "-DWITH_RADOSGW_KAFKA_ENDPOINT=${WITH_RADOSGW_KAFKA_ENDPOINT}"
  "-DWITH_RADOSGW_LUA_PACKAGES=${WITH_RADOSGW_LUA_PACKAGES}"
  "-DWITH_RADOSGW_MOTR=${WITH_RADOSGW_MOTR}"
  "-DWITH_RADOSGW_SELECT_PARQUET=${WITH_RADOSGW_SELECT_PARQUET}"
  "-DWITH_RDMA=${WITH_RDMA}"
  "-DWITH_SYSTEM_BOOST=${WITH_SYSTEM_BOOST}"
  "-DWITH_TESTS=${WITH_TESTS}"
  "${CEPH_CMAKE_ARGS}"
)

_configure() {
  echo "Configuring Buildenv ..."
  echo "CEPH_DIR=${CEPH_DIR}"
  echo "NPROC=${NPROC}"
  echo "CCACHE_DIR=${S3GW_CCACHE_DIR}"
  # shellcheck disable=SC2068
  for e in ${CEPH_CMAKE_ARGS[@]} ; do
    echo "${e}"
  done

  cd "${CEPH_DIR}"

  export CCACHE_DIR="${S3GW_CCACHE_DIR}"
  if [ ! -d "${CCACHE_DIR}" ]; then
    echo "ccache dir not found, create."
    mkdir "${CCACHE_DIR}"
    echo "Created by aquarist-labs/s3gw-tools build-radosgw container" > \
      "${CCACHE_DIR}/README"
  fi

  # This is necessary since git v2.35.2 because of CVE-2022-24765
  # but we have to continue in case CEPH_DIR is not a git repo
  # Since git 2.36 the the wildcard '*' is also accepted
  if ! git config --global safe.directory > /dev/null ; then
    git config --global --add safe.directory "*" || true
  fi

  if [ ! -d "${S3GW_BUILD_DIR}" ] ; then
    echo "build dir not found, create."
    mkdir "${S3GW_BUILD_DIR}"
  fi

  cd "${S3GW_BUILD_DIR}"
  # shellcheck disable=SC2068
  cmake ${CEPH_CMAKE_ARGS[@]} ..
}

_build() {
  cd "${S3GW_BUILD_DIR}"

  make -j"${NPROC}" radosgw

  if [ "${WITH_TESTS}" == "ON" ] ; then
    make -j"${NPROC}" \
      unittest_rgw_sfs_sqlite_users \
      unittest_rgw_sfs_sqlite_buckets \
      unittest_rgw_sfs_sqlite_objects \
      unittest_rgw_sfs_sqlite_versioned_objects \
      unittest_rgw_sfs_sfs_bucket \
      unittest_rgw_sfs_metadata_compatibility \
      unittest_rgw_sfs_gc
  fi
}

_strip() {
  # don't strip debug builds
  [ "${CMAKE_BUILD_TYPE}" == "Debug" ] \
    || [ "${CMAKE_BUILD_TYPE}" == "RelWithDebInfo" ] \
    && return 0

  echo "Stripping files ..."
  strip \
    --strip-debug \
    --strip-unneeded \
    --remove-section=.comment \
    --remove-section=.note.* \
    "${CEPH_DIR}"/build/bin/radosgw \
    "${CEPH_DIR}"/build/lib/*.so
}

_configure
_build
_strip
