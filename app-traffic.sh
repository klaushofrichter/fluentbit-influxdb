#!/bin/bash
# this generates random traffic for the app
set -e
source ./config.sh

DELAY="0.5"  # half a second delay between API calls. Overwrite with second argument

[ -z "$1" ] && echo "need one argument to generate traffic, e.g. 10 or 20. Exit." && exit 1
[ ! -z "$2" ] && DELAY=$2
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1


echo
echo "==== $0: Generating $1 API calls to http://localhost:${HTTPPORT} with $DELAY seconds delay between the calls."
i="0"
while [ ${i} -lt $1 ] 
do
  i=$(( ${i} + 1 ))
  echo -n "$0: $i/$1: "
  if [ $(( $RANDOM % 2 )) == 0 ]; then
    echo -n "info: "
    curl http://localhost:${HTTPPORT}/service/info
  else
    echo -n "random: "
    curl http://localhost:${HTTPPORT}/service/random
  fi
  echo
  sleep ${DELAY}
done
