#!/bin/sh

set -e

# https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html
# Release: Your typical release build with no debugging information and full optimization.
# MinSizeRel: A special Release build optimized for size rather than speed.
# RelWithDebInfo: Same as Release, but with debugging information.
# Debug: Usually a classic debug build including debugging information, no optimization etc.
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

CEPH_DIR=$(realpath ${CEPH_DIR:-"/srv/ceph"})
S3GW_CCACHE_DIR=${S3GW_CCACHE_DIR:-"${CEPH_DIR}/build.ccache"}
WITH_TESTS=${WITH_TESTS:-"OFF"}
WITH_RADOSGW_DBSTORE=${WITH_RADOSGW_DBSTORE:-"OFF"}

CEPH_CMAKE_ARGS=(
  "-DCMAKE_C_COMPILER=gcc-11"
  "-DCMAKE_CXX_COMPILER=g++-11"
  "-DENABLE_GIT_VERSION=ON"
  "-DWITH_PYTHON3=3"
  "-DWITH_CCACHE=ON"
  "-DWITH_TESTS=${WITH_TESTS}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DWITH_RADOSGW_AMQP_ENDPOINT=OFF"
  "-DWITH_RADOSGW_KAFKA_ENDPOINT=OFF"
  "-DWITH_RADOSGW_SELECT_PARQUET=OFF"
  "-DWITH_RADOSGW_MOTR=OFF"
  "-DWITH_RADOSGW_DBSTORE=${WITH_RADOSGW_DBSTORE}"
  "-DWITH_RADOSGW_LUA_PACKAGES=OFF"
  "-DWITH_MANPAGE=OFF"
  "-DWITH_OPENLDAP=OFF"
  "-DWITH_LTTNG=OFF"
  "-DWITH_RDMA=OFF"
  "-DWITH_SYSTEM_BOOST=ON"
  ${CEPH_CMAKE_ARGS}
)
NPROC=${NPROC:-$(nproc --ignore=2)}

build_radosgw() {
  echo "Building radosgw ..."
  echo "CEPH_DIR=${CEPH_DIR}"
  echo "NPROC=${NPROC}"
  echo "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  echo "CCACHE_DIR=${S3GW_CCACHE_DIR}"
  echo "WITH_TESTS=${WITH_TESTS}"
  echo "WITH_RADOSGW_DBSTORE=${WITH_RADOSGW_DBSTORE}"

  export CCACHE_DIR=${S3GW_CCACHE_DIR}
  if [ ! -d "${CCACHE_DIR}" ]; then
    echo "ccache dir not found, create."
    mkdir "${CCACHE_DIR}"
    echo "Created by aquarist-labs/s3gw-tools build-radosgw container" > \
      "${CCACHE_DIR}/README"
  fi

  cd ${CEPH_DIR}

  # This is necessary since git v2.35.2 because of CVE-2022-24765
  # but we have to continue in case CEPH_DIR is not a git repo
  # Since git 2.36 the the wildcard '*' is also accepted
  git config --global --add safe.directory "*" || true

  if [ -d "build" ]; then
      cd build/
      cmake -DBOOST_J=${NPROC} ${CEPH_CMAKE_ARGS[@]} ..
  else
      ./do_cmake.sh ${CEPH_CMAKE_ARGS[@]}
      cd build/
  fi

  ninja -j${NPROC} bin/radosgw
}

strip_radosgw() {
  [ "${CMAKE_BUILD_TYPE}" == "Debug" -o "${CMAKE_BUILD_TYPE}" == "RelWithDebInfo" ] && return 0

  echo "Stripping files ..."
  strip --strip-debug --strip-unneeded \
    --remove-section=.comment --remove-section=.note.* \
    ${CEPH_DIR}/build/bin/radosgw \
    ${CEPH_DIR}/build/lib/*.so
}

build_radosgw_test() {
  echo "Building radosgw test..."

  export CCACHE_DIR=${S3GW_CCACHE_DIR}
  if [ ! -d "${CCACHE_DIR}" ]; then
    echo "ccache dir not found, create."
    mkdir "${CCACHE_DIR}"
    echo "Created by aquarist-labs/s3gw-tools build-radosgw container" > \
      "${CCACHE_DIR}/README"
  fi

  cd ${CEPH_DIR}

  # This is necessary since git v2.35.2 because of CVE-2022-24765
  # but we have to continue in case CEPH_DIR is not a git repo
  git config --global --add safe.directory "*" || true

  if [ -d "build" ]; then
      cd build/
      cmake -DBOOST_J=${NPROC} ${CEPH_CMAKE_ARGS[@]} ..
  else
      ./do_cmake.sh ${CEPH_CMAKE_ARGS[@]}
      cd build/
  fi

  ninja -j${NPROC} bin/unittest_rgw_sfs_sqlite_users
  ninja -j${NPROC} bin/unittest_rgw_sfs_sqlite_buckets
  ninja -j${NPROC} bin/unittest_rgw_sfs_sqlite_objects
  ninja -j${NPROC} bin/unittest_rgw_sfs_sqlite_versioned_objects
  ninja -j${NPROC} bin/unittest_rgw_sfs_sfs_bucket
  ninja -j${NPROC} bin/unittest_rgw_sfs_metadata_compatibility
  ninja -j${NPROC} bin/unittest_rgw_sfs_gc
}

build_radosgw
strip_radosgw

if [ "${WITH_TESTS}" == "ON" ]; then
  build_radosgw_test
fi

exit 0
