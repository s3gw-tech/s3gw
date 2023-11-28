FROM registry.suse.com/bci/bci-base:15.5 as s3gw-base

# This makes sure the Docker cache is invalidated
# if packages in the s3gw repo on OBS have changed
ADD https://download.opensuse.org/repositories/filesystems:/ceph:/s3gw/15.5/repodata/repomd.xml /tmp/repodata-s3gw.xml
# Add OBS repository for additional dependencies necessary on Leap 15.5
RUN zypper ar \
    https://download.opensuse.org/repositories/filesystems:/ceph:/s3gw/15.5/ \
    s3gw-deps \
    && zypper --gpg-auto-import-keys ref

# Try `zypper install` up to three times to workaround mirror timeouts
RUN for i in {1..3} ; do zypper -n install \
    libsqlite3-0=3.43.1 \
    libblkid1 \
    libexpat1 \
    libtcmalloc4 \
    libfmt9 \
    liboath0 \
    libicu-suse65_1 \
    libthrift-0_16_0 \
    libboost_atomic1_80_0 \
    libboost_chrono1_80_0 \
    libboost_context1_80_0 \
    libboost_coroutine1_80_0 \
    libboost_date_time1_80_0 \
    libboost_filesystem1_80_0 \
    libboost_iostreams1_80_0 \
    libboost_program_options1_80_0 \
    libboost_random1_80_0 \
    libboost_regex1_80_0 \
    libboost_serialization1_80_0 \
    libboost_system1_80_0 \
    libboost_thread1_80_0 \
    && break ; done \
    && zypper clean --all \
    && mkdir -p \
    /s3gw/bin \
    /s3gw/lib \
    /data

ENV PATH=/s3gw/bin:$PATH
ENV LD_LIBRARY_PATH=/s3gw/lib:$LD_LIBRARY_PATH

FROM s3gw-base as buildenv

ARG CMAKE_BUILD_TYPE=Debug
ARG SRC_CEPH_DIR=./ceph

ENV SRC_CEPH_DIR=${SRC_CEPH_DIR}
ENV ENABLE_GIT_VERSION=ON

# Needed for extra build deps
ADD https://download.opensuse.org/update/leap/15.5/oss/repodata/repomd.xml /tmp/repodata-update.xml
ADD https://download.opensuse.org/update/leap/15.5/backports/repodata/repomd.xml /tmp/repodata-backports-update.xml
ADD https://download.opensuse.org/update/leap/15.5/sle/repodata/repomd.xml /tmp/repodata-sle-update.xml
RUN zypper ar \
    http://download.opensuse.org/distribution/leap/15.5/repo/oss/ repo-oss \
    && zypper ar http://download.opensuse.org/update/leap/15.5/oss/ repo-update \
    && zypper ar http://download.opensuse.org/update/leap/15.5/backports/ repo-backports-update \
    && zypper ar http://download.opensuse.org/update/leap/15.5/sle/ repo-sle-update \
    && zypper --gpg-auto-import-keys ref

# Try `zypper install` up to three times to workaround mirror timeouts
RUN for i in {1..3} ; do zypper -n install --no-recommends \
    'cmake>3.5' \
    'fmt-devel>=6.2.1' \
    'gperftools-devel>=2.4' \
    'libblkid-devel>=2.17' \
    'liblz4-devel>=1.7' \
    'libthrift-devel>=0.13.0' \
    'pkgconfig(libudev)' \
    'pkgconfig(systemd)' \
    'pkgconfig(udev)' \
    babeltrace-devel \
    binutils \
    ccache \
    cmake \
    cpp12 \
    cryptsetup-devel \
    cunit-devel \
    fdupes \
    fuse-devel \
    gcc-c++ \
    gcc12 \
    gcc12-c++ \
    git \
    gperf \
    gtest \
    gmock \
    jq \
    keyutils-devel \
    libaio-devel \
    libasan6 \
    libboost_atomic1_80_0-devel \
    libboost_context1_80_0-devel \
    libboost_coroutine1_80_0-devel \
    libboost_filesystem1_80_0-devel \
    libboost_iostreams1_80_0-devel \
    libboost_program_options1_80_0-devel \
    libboost_python-py3-1_80_0-devel \
    libboost_random1_80_0-devel \
    libboost_regex1_80_0-devel \
    libboost_system1_80_0-devel \
    libboost_thread1_80_0-devel \
    libbz2-devel \
    libcap-devel \
    libcap-ng-devel \
    libcurl-devel \
    libexpat-devel \
    libicu-devel \
    libnl3-devel \
    liboath-devel \
    libopenssl-devel \
    libpmem-devel \
    libpmemobj-devel \
    librabbitmq-devel \
    librdkafka-devel \
    libstdc++6-devel-gcc12 \
    libtool \
    libtsan0 \
    libxml2-devel \
    lttng-ust-devel \
    lua53-devel \
    lua53-luarocks \
    make \
    memory-constraints \
    mozilla-nss-devel \
    nasm \
    ncurses-devel \
    net-tools \
    ninja \
    ninja \
    openldap2-devel \
    patch \
    perl \
    pkgconfig \
    procps \
    python3 \
    python3-Cython \
    python3-PrettyTable \
    python3-PyYAML \
    python3-Sphinx \
    python3-devel \
    python3-setuptools \
    rdma-core-devel \
    re2-devel \
    rpm-build \
    snappy-devel \
    sqlite-devel \
    systemd-rpm-macros \
    systemd-rpm-macros \
    valgrind-devel \
    xfsprogs-devel \
    xmlstarlet \
    && break ; done \
    && zypper clean --all

COPY $SRC_CEPH_DIR /srv/ceph
# If the ceph source was checked out as a submodule of s3gw, then
# /srv/ceph/.git will now be a regular file containing the string
# "gitdir: ../.git/modules/ceph", and ceph's ENABLE_GIT_VERSION
# magic won't work properly (remember, we're only copying the
# ceph source directory into the build environment, not the parent
# s3gw directory).  Happily, we can cheat by mounting the current
# directory (the one with the s3gw source) into the buildenv, then
# we can run a couple of git commands inside *there* to extract
# the commit hash and version tags ceph needs then save them to
# /srv/ceph/src/.git_version where they'll be picked up by the
# ceph build.  If the ceph source wasn't checked out as a submodule
# of s3gw, /srv/ceph/.git will be a directory as it is in a normal
# git repo, and ceph's ENABLE_GIT_VERSION magic will work as usual.
RUN --mount=target=/tmp/s3gw-git-tmp \
	if [ -f "/srv/ceph/.git" ]; then \
		rm /srv/ceph/.git && \
		cd /tmp/s3gw-git-tmp && \
		(git -C ceph rev-parse HEAD ; git -C ceph describe --long --match 's3gw-v*') 2>/dev/null > /srv/ceph/src/.git_version && \
		echo Using $(cat /srv/ceph/src/.git_version) ; \
	fi

WORKDIR /srv/ceph

ENV WITH_TESTS=ON
RUN /srv/ceph/qa/rgw/store/sfs/build-radosgw.sh

FROM s3gw-base as s3gw-unittests

# Try `zypper install` up to three times to workaround mirror timeouts
RUN for i in {1..3} ; do zypper -n install --no-recommends \
    gtest \
    gmock \
    && break ; done \
    && zypper clean --all

COPY --from=buildenv /srv/ceph/build/bin/unittest_rgw_* /s3gw/bin/
COPY --from=buildenv [ \
    "/srv/ceph/build/lib/librados.so", \
    "/srv/ceph/build/lib/librados.so.2", \
    "/srv/ceph/build/lib/librados.so.2.0.0", \
    "/srv/ceph/build/lib/libceph-common.so", \
    "/srv/ceph/build/lib/libceph-common.so.2", \
    "/s3gw/lib/" ]

ENTRYPOINT [ "bin/bash", "-x", "-c" ]
CMD [ "find /s3gw/bin -name \"unittest_rgw_*\" -print0 | xargs -0 -n1 bash -ec"]

FROM s3gw-base as s3gw

ARG QUAY_EXPIRATION=Never
ARG S3GW_VERSION=Development
ARG S3GW_ID=s3gw

ARG SRC_S3GW_DIR=.

ENV S3GW_ID=${S3GW_ID}
ENV S3GW_DNS_NAME=""
ENV S3GW_DEBUG="none"

LABEL Name=s3gw
LABEL Version=${S3GW_VERSION}
LABEL quay.expires-after=${QUAY_EXPIRATION}

VOLUME ["/data"]

COPY --from=buildenv /srv/ceph/build/bin/radosgw /s3gw/bin
COPY --from=buildenv [ \
    "/srv/ceph/build/lib/librados.so", \
    "/srv/ceph/build/lib/librados.so.2", \
    "/srv/ceph/build/lib/librados.so.2.0.0", \
    "/srv/ceph/build/lib/libceph-common.so", \
    "/srv/ceph/build/lib/libceph-common.so.2", \
    "/s3gw/lib/" ]

COPY ${SRC_S3GW_DIR}/tools/entrypoint.sh /s3gw/bin/

# ports for S3 endpoints
#  http:  7480
#  https: 7481
EXPOSE 7480
EXPOSE 7481
# port for status endpoints
EXPOSE 9090

ENTRYPOINT [ "entrypoint.sh" ]
