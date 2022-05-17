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

function show_ingresses() {
  ip=""
  until [ -n "${ip}" ]
  do
    echo -n "." && sleep 1;
    ip=$(kubectl get -n s3gw-system ingress s3gw-ingress -o 'jsonpath={.status.loadBalancer.ingress[].ip}');
  done
  echo -e "\n"
  echo "Longhorn UI available at http://${ip}:80/longhorn/"
  echo "s3gw available at http://${ip}:80/s3gw/"
  echo -e "\n"
}

function install_on_vm() {
  echo "Proceding to install on a virtual machine"
  WORKER_COUNT=0
  K8S_DISTRO=k3s
  source ./setup_k8s.sh build
}

dev_env=false
use_local_image=0
has_image=false
s3gw_image="ghcr.io/aquarist-labs/s3gw:latest"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dev)
      dev_env=true
      echo "======================================"
      echo "  INSTALLING DEVELOPMENT ENVIRONMENT  "
      echo "======================================"
      echo
      ;;
    --s3gw-image)
      s3gw_image=$2
      has_image=true
      shift 1
      ;;
    --show-ingresses)
      show_ingresses
      exit 0
      ;;
    --vm)
      install_on_vm
      exit 0
      ;;
  esac
  shift
done

if [[ -z "${s3gw_image}" ]]; then
  error "s3gw image not provided"
  exit 1
fi

if $dev_env ; then
  if [[ ! -e "./s3gw.ctr.tar" ]]; then
    echo "Checking for s3gw image locally..."
    img=$(podman images --noheading --sort created s3gw:latest --format '{{.Repository}}:{{.Tag}}' | \
      head -n 1)

    if [[ -z "${img}" ]]; then
      error "Unable to find s3gw image locally; abort."
      exit 1
    fi

    podman image save ${img} -o ./s3gw.ctr.tar || (
      error "Failed to export s3gw image."
      exit 1
    )
  fi
  use_local_image=1
  ! $has_image && s3gw_image="localhost/s3gw:latest"
  echo "Using local s3gw image '${s3gw_image}'."
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

if [ ${use_local_image} -eq 1 ]; then
  echo "Importing local s3gw container image..."
  sudo k3s ctr images import ./s3gw.ctr.tar || (
    error "Failed to import local s3gw image."
    exit 1
  )
else
  echo "Pulling s3gw container image..."
  sudo k3s ctr images pull ${s3gw_image} || (
    error "Failed to pull s3gw image ${s3gw_image}."
    exit 1
  )
fi

# Workaround a K8s behaviour that CustomResourceDefinition must be
# established before they can be used by a resource.
# https://github.com/kubernetes/kubectl/issues/1117
# k3s kubectl wait --for=condition=established --timeout=60s crd middlewares.traefik.containo.us
echo -n "Waiting for CRD to be established..."
while [[ $(kubectl get crd middlewares.traefik.containo.us -o 'jsonpath={..status.conditions[?(@.type=="Established")].status}' 2>/dev/null) != "True" ]]; do
   echo -n "." && sleep 1;
done
echo

s3gw_yaml="s3gw.yaml"
$dev_env && s3gw_yaml="s3gw-dev.yaml"

if [[ -e ${s3gw_yaml} ]]; then
  apply "Installing s3gw from spec file at '${s3gw_yaml}'..." ${s3gw_yaml}
elif [[ -e "generate-spec.sh" ]]; then
  extra=""
  $dev_env && extra="--dev"
  echo "Generating s3gw spec file at '${s3gw_yaml}'..."
  ./generate-spec.sh --output ${s3gw_yaml} ${extra}
  apply "Installing s3gw from spec file at '${s3gw_yaml}'..." ${s3gw_yaml}
else
  echo "Installing s3gw..."
  k3s kubectl apply \
    -f ${ghraw}/aquarist-labs/s3gw-core/main/k3s/s3gw.yaml || (
    error "Failed to install s3gw."
    exit 1
  )
fi

echo -n "Waiting for cluster to become ready..."
show_ingresses
