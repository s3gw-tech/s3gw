#!/bin/bash
set -e
set -u

: "${USE_SSL:=false}"
: "${S3GW_CHARTS:="https://aquarist-labs.github.io/s3gw-charts/"}"

if ! [[ $S3GW_CHARTS =~ https?:// || -r "${S3GW_CHARTS}/Chart.yaml" ]]; then
	echo "S3GW_CHARTS set to something weird ($S3GW_CHARTS)"
	echo "Please set to the s3gw charts dir (e.g s3gw-charts/charts/s3gw) or a remote location"
	exit 1
fi

set -x

minikube start --driver=kvm2 --extra-disks=0

helm repo add jetstack https://charts.jetstack.io
helm repo add traefik https://traefik.github.io/charts

helm repo update

backend_proto="http"

if [[ $USE_SSL == "true" ]]; then
	backend_proto="https"
	helm install cert-manager \
		--namespace cert-manager jetstack/cert-manager \
		--create-namespace \
		--set installCRDs=true \
		--set extraArgs[0]=--enable-certificate-owner-ref=true
fi
helm install traefik-ingress traefik/traefik

traefik_cluster_ip="$(kubectl \
	get service \
	traefik-ingress -ojsonpath='{.spec.clusterIP}')"
helm_values_file="$(mktemp)"
trap "rm $helm_values_file" EXIT

cat >"$helm_values_file" <<EOF
ingress:
  enabled: true
useCertManager: ${USE_SSL}
certManagerNamespace: cert-manager
tlsIssuer: "s3gw-issuer"
email: "mail@example.com"
ui:
  enabled: true
  serviceName: "s3gw-ui"
  publicDomain: "fe.${traefik_cluster_ip}.omg.howdoi.website"
  backendProtocol: "${backend_proto}"
serviceName: "s3gw"
useExistingSecret: false
defaultUserCredentialsSecret: "s3gw-creds"
accessKey: "test"
secretKey: "test"
publicDomain: "be.${traefik_cluster_ip}.omg.howdoi.website"
privateDomain: "svc.cluster.local"
storageSize: 10Gi
storageClass:
  name: "standard"
  create: false
logLevel: "1"
EOF

helm install s3gw "${S3GW_CHARTS}" \
	--namespace s3gw \
	--create-namespace \
	-f "$helm_values_file"

set +x

echo "Please wait a sec until all pods are up"

minikube tunnel

echo "You may want to run minikube delete"
