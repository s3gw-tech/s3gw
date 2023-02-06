#!/bin/bash

# This script should be used while doing development on s3gw's radosgw binaries.
# By calling this script, we patch the s3gw deployment inside k8s as this:
#
# 1) A base image is used, ghcr.io/aquarist-labs/s3gw:latest (default).
# 2) We create a PVC and a helper copier pod that mounts that PVC.
# 3) We copy the built binaries on the PVC by calling an equivalent `kubectl cp` command
#    on the copier pod.
#
# 4) We mount the same PVC on the s3gw pod at the location where
#    the binaries are expected (/radosgw).
#
# Patching the deployment forces the s3gw pod to restart with the new binaries in place.

set -e
timeout=120s
clean_data=false

RADOSGW_BUILD_PATH="${RADOSGW_BUILD_PATH:-"./build"}"
S3GW_DEPLOYMENT_NS="${S3GW_DEPLOYMENT_NS:-"default"}"
S3GW_DEPLOYMENT_BI="${S3GW_DEPLOYMENT_BI:-"ghcr.io/aquarist-labs/s3gw:latest"}"
PVC_STORAGE_CLASS="${PVC_STORAGE_CLASS:-"longhorn"}"

error() {
  echo "error: $*" >/dev/stderr
}

usage() {
  cat << EOF
usage: $0 CMD [args...]

options
  --clean-data    Specifies whether delete the /data content in the s3gw pod.

env variables
  RADOSGW_BUILD_PATH    Specifies the Ceph output build directory.
  S3GW_DEPLOYMENT_NS    Specifies the s3gw namespace in Kubernetes.
  S3GW_DEPLOYMENT_BI    Specifies the s3gw image to be used when patching the s3gw deployment.
  PVC_STORAGE_CLASS     Specifies the storage class to be used for the radosgw-binary PVC.

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --clean-data)
      clean_data=true
      shift 1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

echo
echo Deployment patch configuration
echo "  - binaries location:    ${RADOSGW_BUILD_PATH}"
echo "  - s3gw namespace:       ${S3GW_DEPLOYMENT_NS}"
echo "  - s3gw base image:      ${S3GW_DEPLOYMENT_BI}"
echo "  - pvc storage class:    ${PVC_STORAGE_CLASS}"
echo "  - Cleaning s3gw data:   ${clean_data}"
echo

items=(
    ${RADOSGW_BUILD_PATH}/bin/radosgw
    ${RADOSGW_BUILD_PATH}/lib/libceph-common.so
    ${RADOSGW_BUILD_PATH}/lib/libceph-common.so.2
    ${RADOSGW_BUILD_PATH}/lib/libradosgw.so
    ${RADOSGW_BUILD_PATH}/lib/libradosgw.so.2
    ${RADOSGW_BUILD_PATH}/lib/libradosgw.so.2.0.0
    ${RADOSGW_BUILD_PATH}/lib/librados.so
    ${RADOSGW_BUILD_PATH}/lib/librados.so.2
    ${RADOSGW_BUILD_PATH}/lib/librados.so.2.0.0
)

TAR_ITEMS=""
for item in ${items[@]}; do
  TAR_ITEMS=$TAR_ITEMS$item" "
done

echo "Creating the radosgw-binary PVC..."
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: radosgw-binary
  namespace: $S3GW_DEPLOYMENT_NS
spec:
  storageClassName: $PVC_STORAGE_CLASS
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF

echo "Creating the radosgw-copier Pod..."
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: radosgw-copier
  namespace: $S3GW_DEPLOYMENT_NS
spec:
  volumes:
    - name: radosgw-binary
      persistentVolumeClaim:
        claimName: radosgw-binary
    - name: s3gw-store
      persistentVolumeClaim:
        claimName: s3gw-pvc
  containers:
    - name: copier
      image: busybox:stable
      command: ["/bin/sh", "-ec", "trap : TERM INT; sleep infinity & wait"]
      volumeMounts:
        - mountPath: "/radosgw"
          name: radosgw-binary
        - mountPath: "/data"
          name: s3gw-store
EOF

echo "Waiting for radosgw-copier Pod to be ready..."
kubectl wait --for=condition=ready --timeout=$timeout pod -n $S3GW_DEPLOYMENT_NS radosgw-copier

echo "Copying items on the radosgw-binary PVC..."
kubectl exec -i -n $S3GW_DEPLOYMENT_NS -c copier radosgw-copier -- rm -rf /radosgw/*
( tar cf - ${TAR_ITEMS}
) | kubectl exec -i -n $S3GW_DEPLOYMENT_NS -c copier radosgw-copier -- tar xfv -
for item in ${items[@]}; do
  kubectl exec -i -n $S3GW_DEPLOYMENT_NS -c copier radosgw-copier -- mv $item /radosgw/
done
kubectl exec -i -n $S3GW_DEPLOYMENT_NS -c copier radosgw-copier -- chmod ugo+x /radosgw/radosgw

if $clean_data ; then
    echo "Cleaning s3gw data ..."
    kubectl exec -i -n $S3GW_DEPLOYMENT_NS -c copier radosgw-copier -- sh -c "rm -rf /data/*"
fi

echo "Deleting the radosgw-copier to avoid multi-attach issue between pods..."
kubectl delete pod -n $S3GW_DEPLOYMENT_NS radosgw-copier

RADOSGW_BINARY_HASH=$(shasum ${RADOSGW_BUILD_PATH}/bin/radosgw | cut -f 1 -d " ")
echo "radosgw binary hash: $RADOSGW_BINARY_HASH"

echo "Patching the s3gw deployment to use the copied radosgw's binary..."
PATCH=$(cat <<EOF
{ "spec": {
        "selector": {
            "matchLabels": {
                "app.kubernetes.io/component": "gateway",
                "app.kubernetes.io/instance": "s3gw",
                "app.kubernetes.io/name": "s3gw"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app.kubernetes.io/component": "gateway",
                    "app.kubernetes.io/instance": "s3gw",
                    "app.kubernetes.io/name": "s3gw"
                },
                "annotations": {
                  "binary-hash": "${RADOSGW_BINARY_HASH}"
                }
            },
            "spec": {
                "containers": [
                    {
                        "envFrom": [
                            {
                                "configMapRef": {
                                    "name": "s3gw-config"
                                }
                            },
                            {
                                "secretRef": {
                                    "name": "s3gw-secret"
                                }
                            }
                        ],
                        "image": "${S3GW_DEPLOYMENT_BI}",
                        "imagePullPolicy": "IfNotPresent",
                        "name": "s3gw",
                        "ports": [
                            {
                                "containerPort": 7480,
                                "name": "s3",
                                "protocol": "TCP"
                            }
                        ],
                        "volumeMounts": [
                            {
                                "mountPath": "/data",
                                "name": "s3gw-lh-store"
                            },
                            {
                                "mountPath": "/radosgw",
                                "name": "radosgw-binary"
                            }
                        ]
                    }
                ],
                "imagePullSecrets": [
                    {
                        "name": "s3gw-image-pull-secret"
                    }
                ],
                "volumes": [
                    {
                        "name": "s3gw-lh-store",
                        "persistentVolumeClaim": {
                            "claimName": "s3gw-pvc"
                        }
                    },
                    {
                        "name":"radosgw-binary",
                        "persistentVolumeClaim": {
                            "claimName": "radosgw-binary"
                        }
                    }
                ]
            }
        }
    }
}
EOF
)

kubectl patch deployment -n $S3GW_DEPLOYMENT_NS s3gw -p "${PATCH}"

echo "Waiting for the deployment's rollout to complete..."
kubectl rollout status deployment -n $S3GW_DEPLOYMENT_NS s3gw --timeout=$timeout
