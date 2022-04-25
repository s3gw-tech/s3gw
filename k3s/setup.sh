#!/bin/bash
# setup.sh - setup a k3s cluster with longhorn and s3gw
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

set -e

ghraw="https://raw.githubusercontent.com"

function apply() {
  desc=${1}
  yaml=${2}

  [[ -z "${desc}" || -z "${yaml}" ]] && \
    echo "missing parameters to function apply" && \
    exit 1

  echo "creating ${desc}..."
  k3s kubectl apply -f ./${yaml} || (
    echo "error creating ${desc}"
    exit 1
  )
}

if [[ ! -e "./s3gw.ctr.tar" ]]; then
  echo "check for s3gw image locally..."
  img=$(podman images --format '{{.Repository}}:{{.Tag}}' | \
    grep 's3gw:latest')

  if [[ -z "${img}" ]]; then
    echo "unable to find s3gw image locally; abort."
    exit 1
  fi

  podman image save ${img} -o ./s3gw.ctr.tar || (
    echo "error exporting s3gw image"
    exit 1
  )
fi

if k3s --version >&/dev/null ; then
  echo "k3s already installed, we won't proceed."
  exit 0
fi

echo "install k3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 || (
  echo "error installing k3s."
  exit 1
)

# https://longhorn.io/docs/1.2.4/deploy/install/#installing-open-iscsi
echo "install iscsi..."
k3s kubectl apply \
  -f ${ghraw}/longhorn/longhorn/v1.2.4/deploy/prerequisite/longhorn-iscsi-installation.yaml || (
  echo "error installing iscsi."
  exit 1
)

echo "install longhorn..."
k3s kubectl apply \
  -f ${ghraw}/longhorn/longhorn/v1.2.4/deploy/longhorn.yaml || (
  echo "error installing longhorn."
  exit 1
)

echo "import s3gw container image..."
sudo k3s ctr images import ./s3gw.ctr.tar || (
  echo "error importing s3gw image."
  exit 1
)

apply "longhorn storage class" longhorn-storageclass.yaml
apply "longhorn persistent volume claim" longhorn-pvc.yaml
apply "s3gw pod" s3gw-pod.yaml
apply "s3gw service" s3gw-service.yaml
apply "s3gw ingress" s3gw-ingress.yaml

echo "wait a bit, allow us to get an ip..."
sleep 30

ip=$(k3s kubectl get ingress s3gw-ingress \
  -o jsonpath='{.status.loadBalancer.ingress[].ip}')

echo "s3gw available at http://${ip}:80"
