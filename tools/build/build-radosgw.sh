#!/bin/bash

set -e

CEPH_DIR=$(realpath ${CEPH_DIR:-"/srv/ceph"})
BUILD_SCRIPT=${BUILD_SCRIPT:-"${CEPH_DIR}/qa/rgw/store/sfs/build-radosgw.sh"}
${BUILD_SCRIPT}
exit 0
