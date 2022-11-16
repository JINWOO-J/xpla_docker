#!/bin/bash
shopt -u nocasematch # disable
export NETWORK=${NETWORK:-"mainnet"}
export DATA_DIR=${DATA_DIR:-"/data/${NETWORK}/.xpla"}
export LOG_PATH=${LOG_PATH:-"/data/${NETWORK}/logs"}

export INIT_FILE=${INIT_FILE:-"${DATA_DIR}/initialized"}
#export HOME=${DATA_DIR} ## DATA_DIR path e.g) /data/.xpla
export LOG_FORMAT=${LOG_FORMAT:-"plain"}
export LOG_LEVEL=${LOG_LEVEL:-"info"}
export GLOBAL_OPT="--home ${DATA_DIR} --log_format ${LOG_FORMAT} --log_level ${LOG_LEVEL}"

export ROLE=${ROLE:-"sentry"}
export STDOUT=${STDOUT:-"true"}
export MONIKER=${MONIKER:-"iconloop"}
export IS_AUTOGEN_CERT=${IS_AUTOGEN_CERT:-"false"}
export KEY_PASSWORD=${KEY_PASSWORD:-"iconloop"}
export KEY_NAME=${KEY_NAME:-"iconloop_rnd_key"}
export STAT_INTERVAL=${STAT_INTERVAL:-"10"}
export FORCE_INIT=${FORCE_INIT:-"false"}

#mkdir -p "$LOG_PATH"

declare -A networks=(
    ["mainnet"]="dimension_37-1"
    ["testnet"]="cube_47-5"
)

# https://github.com/xpladev/mainnet
# https://github.com/xpladev/testnets
if [[ "${ROLE}" == "sentry" ]]
then
    declare -A seeds=(
        ["mainnet"]="15efa0a83dff372752369cc984492d9ee72f332b@54.81.115.88:26656,e0d49fdef6aff95ed290ca4acafa2fdd312abd99@35.79.122.205:26656,d5c5908a5390b2278180ce975d94d4a43da4952b@34.89.191.254:26656"
        ["testnet"]="9ddfac28dc6b28601e3039902ee5a8915dc7891f@3.35.54.221:26656"
    )
elif [[ "${ROLE}" == "validator" ]]
then
    declare -A seeds=(
        ["mainnet"]="e7b6016ce5663a69ba71a982072315545eb0d5f6@seed.xpla.delightlabs.io:26656"
        ["testnet"]="9ddfac28dc6b28601e3039902ee5a8915dc7891f@3.35.54.221:26656"
    )
else
    echo "Invalid Role, input '${ROLE}' => allows 'sentry', 'validator' "
    exit 1
fi

export config_p2p__seeds=${config_p2p__seeds:-${seeds[${NETWORK}]}}
export NETWORK_ID=${networks[$NETWORK]}

alias xplad="xplad ${GLOBAL_OPT}"
