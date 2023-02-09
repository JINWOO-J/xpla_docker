#!/usr/bin/env python3
import common
import os
from pawnlib.config import pawnlib_config as pawn
from pawnlib.typing import FlatDict, str2bool, return_guess_type, guess_type


def dict_to_environment(_dict):
    for k, v in _dict.items():
        os.environ[k] = str(v)

environments = {
    "LOG_PATH": "data/logs",
    "DATA_DIR": "data",
    "app_minimum-gas-prices" : "850000000000axpl",
    "app_evm__tracer" : "",
    "app_evm__max-tx-gas-wanted" : 0,
    "app_json-rpc__enable" : False,
    "app_json-rpc__address" : "0.0.0.0:8545",
    "app_json-rpc__gas-cap" : 25000000,
    "app_json-rpc__evm-timeout" : "5s",
    "app_json-rpc__txfee-cap" : "1",
    "app_json-rpc__filter-cap" : "200",
    "app_json-rpc__feehistory-cap" : "100",
    "app_json-rpc__logs-cap" : "10000",
    "app_json-rpc__block-range-cap" : "10000",
    "app_json-rpc__http-timeout" : "30s",
    "app_json-rpc__http-idle-timeout" : "2m0s",
    "app_json-rpc__allow-unprotected-txs" : "false",
    "app_json-rpc__max-open-connections" : 0,
    "app_json-rpc__enable-indexer" : False,

}

dict_to_environment(environments)
pawn.set(PAWN_DEBUG=True)


from src import env_to_config

env_to_config.main(dry_run=False)
