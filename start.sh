#!/bin/bash
set -e

# read common settings
source ./config.sh

#
# remove cluster if it exists
if [[ ! -z $(k3d cluster list | grep "^${CLUSTER}") ]]; then
  echo
  echo "==== $0: remove existing cluster"
  read -p "K3D cluster \"${CLUSTER}\" exists. Ok to delete it and restart? (y/n) " -n 1 -r
  echo
  if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
    echo "bailing out..."
    exit 1
  fi
  k3d cluster delete ${CLUSTER}
fi  

echo
echo "==== $0: retrieve app name and version"
export APP=`cat package.json | grep '^  \"name\":' | cut -d ' ' -f 4 | tr -d '",'`         # extract app name from package.json
export VERSION=`cat package.json | grep '^  \"version\":' | cut -d ' ' -f 4 | tr -d '",'`  # extract version from package.json
echo "Appname is ${APP}, version ${VERSION}"

echo
echo "==== $0: Create new cluster ${CLUSTER} for app ${APP}:${VERSION}"
echo -n "sending Slack message to announce the setup..."
./slack.sh "Cluster ${CLUSTER} setup in progress...."
cat k3d-config.yaml.template | envsubst "${ENVSUBSTVAR}" > /tmp/k3d-config.yaml
k3d cluster create --config /tmp/k3d-config.yaml
rm /tmp/k3d-config.yaml
export KUBECONFIG=$(k3d kubeconfig write ${CLUSTER})
echo "export KUBECONFIG=${KUBECONFIG}"

echo
echo "==== $0: Loading helm repositories"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add fluent https://fluent.github.io/helm-charts
helm repo add influxdata https://helm.influxdata.com/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo
echo "==== $0: Installing Prometheus CRDs before installing Prometheus itself"
BASE="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${PROMOPERATOR}/example/prometheus-operator-crd"
CRDS="alertmanagerconfigs alertmanagers podmonitors probes prometheuses prometheusrules servicemonitors thanosrulers"
for crd in ${CRDS} 
do
  kubectl create -f ${BASE}/monitoring.coreos.com_${crd}.yaml
done

#
# deploy ingress-nginx
./ingress-nginx-deploy.sh

#
# undeploy and deploy influxdb
./influxdb-deploy.sh

#
# undeploy and deploy fluentbit
./fluentbit-deploy.sh

#
# build and deploy the application
./app-deploy.sh

#
# deploy prometheus/alertmanager/grafana
./prom-deploy.sh

#
# generate a little traffic
./app-traffic.sh 3

echo 
echo "==== $0: Various information"
echo -n "Sending Slack message to announce deployment. "
./slack.sh "Cluster ${CLUSTER} running."
echo "export KUBECONFIG=${KUBECONFIG}"
echo "Lens metrics setting: monitoring/prom-kube-prometheus-stack-prometheus:9090/prom"
echo "${APP} info API: http://localhost:${HTTPPORT}/service/info"
echo "${APP} random API: http://localhost:${HTTPPORT}/service/random"
echo "${APP} metrics API: http://localhost:${HTTPPORT}/service/metrics"
echo "influxdb ui: http://localhost:31080"
echo "prometheus: http://localhost:${HTTPPORT}/prom/targets"
echo "grafana: http://localhost:${HTTPPORT}  (use admin/${GRAFANA_PASS} to login)"
echo "alertmanager: http://localhost:${HTTPPORT}/alert"
[ -x ${AMTOOL} ] && sleep 4 && ${AMTOOL} config routes
