#!/bin/sh

set -e

CEPH_DIR=$(realpath ${CEPH_DIR:-"/srv/ceph"})
CEPH_CMAKE_ARGS="-DENABLE_GIT_VERSION=ON -DWITH_PYTHON3=3 -DWITH_CCACHE=ON ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_AMQP_ENDPOINT=OFF -DWITH_RADOSGW_KAFKA_ENDPOINT=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_SELECT_PARQUET=OFF -DWITH_RADOSGW_MOTR=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_DBSTORE=ON -DWITH_RADOSGW_LUA_PACKAGES=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_MANPAGE=OFF -DWITH_OPENLDAP=OFF -DWITH_LTTNG=OFF ${CEPH_CMAKE_ARGS}"
NPROC=${NPROC:-$(nproc --ignore=2)}

build_radosgw_binary() {
  echo "Building radosgw binary ..."
  echo "CEPH_DIR=${CEPH_DIR}"
  echo "NPROC=${NPROC}"

  cd ${CEPH_DIR}

  ./install-deps.sh || true

  if [ -d "build" ]; then
      cd build/
      cmake -DBOOST_J=${NPROC} ${CEPH_CMAKE_ARGS} ..
  else
      ./do_cmake.sh ${CEPH_CMAKE_ARGS}
      cd build/
  fi

  ninja -j${NPROC} bin/radosgw
}

build_radosgw_binary

exit 0
