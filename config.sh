# customize the values below
export HTTPPORT=8080
export INFLUXUIPORT=31080
export INFLUXPORT=31081
export CLUSTER=mycluster
export GRAFANA_PASS="operator"
export INFLUXDB_ADMIN_PASSWORD="password"

# SLACKWEBHOOK this is a URL like this: https://hooks.slack.com/services/DFE$$RFSFSZ/FSFRGRGRRQ/afsdfsjisjfijgsjdsfjfooj
# create one via https://api.slack.com/apps  ( create new app and generate a webhook URL)
export SLACKWEBHOOK=$(cat ../.slack/SLACKWEBHOOK.url)

# Helm chart versions
INFLUXDBCHART="4.10.2"
INGRESSNGINXCHART="4.0.9"
FLUENTBITCHART="0.19.6"
KUBEPROMETHEUSSTACKCHART="21.0.3"
PROMOPERATOR="0.52.0"  # this is for Prometheus' CRDs. The version must fit to the chart version.

# path to AMTOOL if available. Extract from https://github.com/prometheus/alertmanager/releases
export AMTOOL=~/bin/amtool

# usually there is no need to do something below this line
ENVSUBSTVAR='$HTTPPORT $CLUSTER $APP $GRAFANA_PASS $SLACKWEBHOOK $AMTOOL $AMTOOLCONFIG $VERSION $INFLUXPORT $INFLUXUIPORT'
export APP=`cat package.json | grep '^  \"name\":' | cut -d ' ' -f 4 | tr -d '",'`
export VERSION=`cat package.json | grep '^  \"version\":' | cut -d ' ' -f 4 | tr -d '",'`
AMTOOLCONFIG=~/.config/amtool/config.yml
[ -x ${AMTOOL} ] && mkdir -p `dirname ${AMTOOLCONFIG}` && cat amtool-config.yaml.template | envsubst > ${AMTOOLCONFIG}

