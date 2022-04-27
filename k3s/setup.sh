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

function error() {
  echo "[ERROR] ${@}" >&2
}

function apply() {
  desc=${1}
  yaml=${2}

  [[ -z "${desc}" || -z "${yaml}" ]] && \
    error "Missing parameters to function apply." && \
    exit 1

  echo "Creating ${desc}..."
  k3s kubectl apply -f ./${yaml} || (
    error "Failed to create ${desc}."
    exit 1
  )
}

if [[ ! -e "./s3gw.ctr.tar" ]]; then
  echo "Checking for s3gw image locally..."
  img=$(podman images --format '{{.Repository}}:{{.Tag}}' | \
    grep 's3gw:latest')

  if [[ -z "${img}" ]]; then
    error "Unable to find s3gw image locally; abort."
    exit 1
  fi

  podman image save ${img} -o ./s3gw.ctr.tar || (
    error "Failed to export s3gw image."
    exit 1
  )
fi

if k3s --version >&/dev/null ; then
  error "K3s already installed, we won't proceed."
  exit 0
fi

echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 || (
  error "Failed to install K3s."
  exit 1
)

# https://longhorn.io/docs/1.2.4/deploy/install/#installing-open-iscsi
echo "Installing iscsi..."
k3s kubectl apply \
  -f ${ghraw}/longhorn/longhorn/v1.2.4/deploy/prerequisite/longhorn-iscsi-installation.yaml || (
  error "Failed to install iscsi."
  exit 1
)

echo "Installing Longhorn..."
k3s kubectl apply \
  -f ${ghraw}/longhorn/longhorn/v1.2.4/deploy/longhorn.yaml || (
  error "Failed to install Longhorn."
  exit 1
)

echo "Importing s3gw container image..."
sudo k3s ctr images import ./s3gw.ctr.tar || (
  error "Failed to import s3gw image."
  exit 1
)

# Workaround a k8s behaviour that CustomResourceDefinition must be
# established before they can be used by a resource.
# https://github.com/kubernetes/kubectl/issues/1117
# k3s kubectl wait --for=condition=established --timeout=60s crd middlewares.traefik.containo.us
echo -n "Waiting for CRD to be established..."
while [[ $(kubectl get crd middlewares.traefik.containo.us -o 'jsonpath={..status.conditions[?(@.type=="Established")].status}' 2>/dev/null) != "True" ]]; do
   echo -n "." && sleep 1;
done
echo

apply "longhorn storage class" longhorn-storageclass.yaml
apply "s3gw namespace" s3gw-namespace.yaml
apply "s3gw persistent volume claim" s3gw-pvc.yaml
apply "s3gw pod" s3gw-pod.yaml
apply "s3gw service" s3gw-service.yaml
apply "s3gw ingress" s3gw-ingress.yaml
apply "longhorn ingress" longhorn-ingress.yaml

echo -n "Waiting for cluster to become ready..."
ip=""
until [ -n "${ip}" ]
do
  echo -n "." && sleep 1;
  ip=$(kubectl get -n s3gw-system ingress s3gw-ingress -o 'jsonpath={.status.loadBalancer.ingress[].ip}');
done
echo -e "\n\n"
echo "Longhorn UI available at http://${ip}:80/longhorn/"
echo "s3gw available at http://${ip}:80/s3gw/"
