#!/bin/bash

trap "exit 130" SIGINT
trap "exit 137" SIGKILL
trap "exit 143" SIGTERM

set -o errexit
set -o nounset
set -o pipefail

ELASTICPOT_JSON='/etc/elasticpot/elasticpot.json'

main () {

    DEBUG=${DEBUG:-false}
    if [[ ${DEBUG} == "true" ]]
    then
      set -o xtrace
    fi

    local tags=${TAGS:-}
    local ipv6=${IPV6_ENABLE:-"false"}
    if [[ -z ${DEPLOY_KEY} ]]
    then
      echo "[CRIT] - No deploy key found"
      exit 1
    fi

    # Register this host with CHN if needed
    chn-register.py \
        -p elasticpot \
        -d "${DEPLOY_KEY}" \
        -u "${CHN_SERVER}" -k\
        -o "${ELASTICPOT_JSON}" \
        -i "${REPORTED_IP}"

    local uid="$(cat ${ELASTICPOT_JSON} | jq -r .identifier)"
    local secret="$(cat ${ELASTICPOT_JSON} | jq -r .secret)"

    export ELASTICPOT_output_hpfeed__server="${FEEDS_SERVER}"
    export ELASTICPOT_output_hpfeed__port="${FEEDS_SERVER_PORT:-10000}"
    export ELASTICPOT_output_hpfeed__identifier="${uid}"
    export ELASTICPOT_output_hpfeed__secret="${secret}"
    export ELASTICPOT_output_hpfeed__tags="${TAGS}"
    export ELASTICPOT_output_hpfeed__reported_ip="${REPORTED_IP}"

    containedenv-config-writer.py \
      -p ELASTICPOT_ \
      -f ini \
      -r /code/elasticpot.cfg.template \
      -o /opt/elasticpot/etc/honeypot.cfg

    cd /opt/elasticpot
    python3 elasticpot.py
}

main "$@"
