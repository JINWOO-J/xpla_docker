#!/bin/bash
source /app/environments.sh
shopt -u nocasematch # disable
xplad_cmd="xplad $GLOBAL_OPT"

function today(){
    DATE=$(date '+%Y-%m-%d %T.%3N')
    return "${DATE}"
}

function logging() {
    MSG=$1
    APPEND_STRING=${2:-"\n"}
    LOG_TYPE=${3:-"booting"}
    LOG_PATH=${4:-"$DEFAULT_LOG_PATH"}
    LOG_DATE=$(date +%Y%m%d)
    if [[ ! -e "$LOG_PATH" ]];then
        mkdir -p "$LOG_PATH"
    fi
    if [[ ${APPEND_STRING} == "\n" ]] ;then
        echo -ne "[$(date '+%Y-%m-%d %T.%3N')] $MSG ${APPEND_STRING}" >> "${LOG_PATH}/${LOG_TYPE}_${LOG_DATE}.log"
    else
        echo -ne "$MSG ${APPEND_STRING}" >> "${LOG_PATH}/${LOG_TYPE}_${LOG_DATE}.log"
    fi
}

function initialize_proc(){
    mkdir -p "${DATA_DIR}"
    echo "Initialize NETWORK=${NETWORK_ID}, MONIKER=${MONIKER}"

    for remove_file in "config/genesis.json" "config/priv_validator_key.json" "config/node_key.json";
    do
        if [[ -f "${DATA_DIR}/${remove_file}" ]]; then
            echo "Remove old file - ${DATA_DIR}/${remove_file}"
            rm -rf "${DATA_DIR:?}/${remove_file:?}";
        fi
    done
    $xplad_cmd init ${MONIKER} --chain-id ${NETWORK_ID} 2> >(tee "${DATA_DIR}"/network_info.json)
    cp -rf /app/genesis_${NETWORK}.json  "${DATA_DIR:?}"/config/genesis.json

    env_to_config.py

    echo "NETWORK=${NETWORK} NETWORK_ID=${NETWORK_ID}, MONIKER=${MONIKER}" > ${INIT_FILE}
    if [[ "${IS_AUTOGEN_CERT}" == "true" ]]; then
        generate_random_keys &>> "${DATA_DIR}/${KEY_NAME}_key" ;
    fi
}

function initialize(){
    if [[ "${FORCE_INIT}" == "true" ]]; then
        initialize_proc;
    elif [[ -f "${INIT_FILE}" ]] || [[ -d "${DATA_DIR}" ]]; then
        echo "Already initialized NETWORK=${NETWORK_ID}, MONIKER=${MONIKER}, INIT_FILE=${INIT_FILE}, DATA_DIR=${DATA_DIR}"
    else
        initialize_proc;
    fi
}

function get_keys(){
    echo "Get keys"
    $xplad_cmd keys list <<!
    ${KEY_PASSWORD}
    ${KEY_PASSWORD}
!
}

function generate_random_keys(){
    echo "generate_random_keys"
    $xplad_cmd keys add ${KEY_NAME} <<!
    ${KEY_PASSWORD}
    ${KEY_PASSWORD}
!
}

function import_keys(){
    echo "import_keys"
    $xplad_cmd keys import ${KEY_NAME} <<!
    ${KEY_PASSWORD}
    ${KEY_PASSWORD}
!
}


echo ">> DATA_DIR=${DATA_DIR}, NETWORK=${NETWORK}, LOG_PATH=${LOG_PATH}"

if [[ "$*" == *"init"*  ]]; then
    echo "Network Name: ${networks[$NETWORK]}"
    initialize;
elif [[ "$*" == *"generate_random_keys"* ]]; then
    generate_random_keys &>> "${DATA_DIR}/${KEY_NAME}_key" ;

elif [[ "$*" == *"xplad"* ]]; then
    if [[ "$*" == *"start"*  ]]; then
        initialize;
        env_to_config.py
        if [[ ${STDOUT} == "true" ]]; then
#            $xplad_cmd $@ 2> >(tee ${DATA_DIR}/xpla.log)
            $@ ${GLOBAL_OPT}  2>> >(tee ${LOG_PATH}/xpla.log)
        else
#            $xplad_cmd $@ 2> ${DATA_DIR}/xpla.log
            $@ ${GLOBAL_OPT} &>> ${LOG_PATH}/xpla.log
        fi
    else
        echo "===== STD RUN ===== OPT = ${GLOBAL_OPT}"
        $@ ${GLOBAL_OPT}
    fi
else
    echo "==== ETC EUN ==== "
    $@
fi
