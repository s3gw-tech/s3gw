FROM opensuse/leap:15.4 as s3gw-base

RUN zypper ar \
  https://download.opensuse.org/repositories/filesystems:/ceph:/s3gw/15.4/ \
  s3gw-deps \
 && zypper ar \
  https://download.opensuse.org/repositories/Cloud:/Tools/15.4/ \
  cloud-tools \
 && zypper --gpg-auto-import-keys ref

RUN zypper -n install \
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
 && zypper clean --all \
 && mkdir -p \
  /radosgw/bin \
  /radosgw/lib \
  /data

ENV PATH=/radosgw/bin:$PATH
ENV LD_LIBRARY_PATH=/radosgw/lib:$LD_LIBRARY_PATH

FROM s3gw-base as buildenv

ARG CMAKE_BUILD_TYPE=Debug

ENV SRC_CEPH_DIR="${SRC_CEPH_DIR:-"./ceph"}"
ENV SFS_CCACHE_DIR="/srv/ccache"
ENV SFS_BUILD_DIR="/srv/build"
ENV CCACHE_DIR="${SFS_CCACHE_DIR}"
ENV ENABLE_GIT_VERSION=OFF

# Add OBS repository for additional dependencies necessary on Leap 15.4
RUN zypper -n install --no-recommends \
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
      cpp11 \
      cryptsetup-devel \
      cunit-devel \
      fdupes \
      fuse-devel \
      gcc-c++ \
      gcc11 \
      gcc11-c++ \
      git \
      gperf \
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
      libsqliteorm \
      libstdc++6-devel-gcc11 \
      libtool \
      libtsan0 \
      libxml2-devel \
      lttng-ust-devel \
      lua-devel \
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
      python3-python-magic \
      python3-setuptools \
      rdma-core-devel \
      re2-devel \
      rpm-build \
      s3cmd \
      snappy-devel \
      sqlite-devel \
      systemd-rpm-macros \
      systemd-rpm-macros \
      valgrind-devel \
      xfsprogs-devel \
      xmlstarlet \
 && zypper clean --all


WORKDIR /srv/ceph

ENV WITH_TESTS=ON

SHELL [ "bash", "-e", "-x", "-c" ]

RUN \
  --mount=type=bind,source=$SRC_CEPH_DIR,target=/srv/ceph,readwrite \
  if [ -f /srv/ceph/s3cmd.cfg ] ; then \
    pushd /srv ; \
    s3cmd -c /srv/ceph/s3cmd.cfg get s3://s3gw-cache/ccache.tar ccache.tar ; \
    tar -xf ccache.tar ; \
    popd ; \
  fi \
  && ccache --show-stats \
  && /srv/ceph/qa/rgw/store/sfs/build-radosgw.sh \
  && ccache --show-stats \
  && if [ -f /srv/ceph/s3cmd.cfg ] ; then \
    pushd /srv ; \
    tar -uf /srv/ccache.tar ccache ; \
    s3cmd -c /srv/ceph/s3cmd.cfg put ccache.tar s3://s3gw-cache/ccache.tar ; \
    popd ; \
  fi

FROM s3gw-base as s3gw-unittests

COPY --from=buildenv /srv/build/bin/unittest_rgw_* /radosgw/bin/
COPY --from=buildenv [ \
  "/srv/build/lib/librados.so", \
  "/srv/build/lib/librados.so.2", \
  "/srv/build/lib/librados.so.2.0.0", \
  "/srv/build/lib/libceph-common.so", \
  "/srv/build/lib/libceph-common.so.2", \
  "/radosgw/lib/" ]

ENTRYPOINT [ "bin/bash", "-x", "-c" ]
CMD [ "find /radosgw/bin -name \"unittest_rgw_*\" -print0 | xargs -0 -n1 bash -ec"]

FROM s3gw-base as s3gw

ARG QUAY_EXPIRATION=Never
ARG S3GW_VERSION=Development
ARG ID=s3gw

ENV ID=${ID}

LABEL Name=s3gw
LABEL Version=${S3GW_VERSION}
LABEL quay.expires-after=${QUAY_EXPIRATION}

VOLUME ["/data"]

COPY --from=buildenv /srv/build/bin/radosgw /radosgw/bin
COPY --from=buildenv [ \
  "/srv/build/lib/librados.so", \
  "/srv/build/lib/librados.so.2", \
  "/srv/build/lib/librados.so.2.0.0", \
  "/srv/build/lib/libceph-common.so", \
  "/srv/build/lib/libceph-common.so.2", \
  "/radosgw/lib/" ]

EXPOSE 7480
EXPOSE 7481

ENTRYPOINT [ "radosgw", "-d", \
  "--no-mon-config", \
  "--id", "${ID}", \
  "--rgw-data", "/data/", \
  "--run-dir", "/run/", \
  "--rgw-sfs-data-path", "/data" ]
CMD [ "--rgw-backend-store", "sfs", "--debug-rgw", "1" ]
