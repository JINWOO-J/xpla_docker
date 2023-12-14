#!/usr/bin/env python3
from pawnlib.config import pawnlib_config as pawn
from pawnlib.typing import FlatDict, str2bool, return_guess_type, guess_type
from pawnlib.output import open_file, dump, classdump, is_file
import toml
import os
import json
import re


def parse_env_value(value):
    try:
        # JSON 파싱을 시도하여 Python 데이터 타입으로 변환
        return json.loads(value)
    except json.JSONDecodeError:
        # JSON 파싱이 실패하면 원래의 문자열을 반환
        return value

def parse_env_list(env_value):
    # 환경변수 값의 양 끝 공백 제거
    env_value = env_value.strip()

    # 마지막 문자가 콤마인 경우 제거
    env_value = env_value.strip()
    # 정규식을 사용하여 배열 형식의 문자열을 검사하고 마지막 콤마 제거
    env_value = re.sub(r'\s*,\s*\]', ']', env_value)

    # 문자열을 JSON 배열로 파싱
    try:
        return json.loads(env_value)
    except json.JSONDecodeError:
        # 파싱 실패 시 빈 리스트 반환
        return env_value

def get_config_toml(key=None):
    default_dir = f"{os.environ.get('DATA_DIR')}/config"
    return f"{default_dir}/{key[:-1]}.toml"

def extract_category(config_key):
    if "__" in config_key:
        parsed_config_list = config_key.split("__")
        return f"\[{parsed_config_list[0]}] {parsed_config_list[1]}"
    return config_key

def toml_parser(config_prefix="config_", dry_run=False):
    config_filename = get_config_toml(config_prefix)
    is_updated = "not_changed"
    if is_file(config_filename):
        config_toml = open_file(config_filename)
        config = toml.loads(config_toml)
        config_flat_dict = FlatDict(config, delimiter="__")
        pawn.console.debug(f"[START] Change the config file with environment values - {config_filename}")
        for k, v in os.environ.items():
            if k.startswith(config_prefix):
                config_key = k.replace(config_prefix, "")
                old_value = config_flat_dict.get(config_key)
                # v = return_guess_type(v)
                v = parse_env_list(v)  # 환경 변수의 값을 적절한 데이터 타입으로 변환


                if old_value != v and dry_run == False:
                    pawn.app_logger.info(f"[CHANGE] key={config_key}, old={old_value}, new={v}, config_file={config_filename}")
                    config_flat_dict[config_key] = v
                    is_updated = "changed"

                pawn.console.debug(f"[{is_updated.upper()}] key={extract_category(config_key):<25} , "
                                   f"old={old_value}({type(old_value)}), new={v}({type(v)}), config_file={config_filename}")

        if is_updated == "changed":
            with open(config_filename, "w") as toml_file:
                toml.dump(config_flat_dict.as_dict(), toml_file)
    else:
        pawn.app_logger.info(f"{config_filename} not found")


def main(dry_run=False):

    env_value = '["/ibc.core.channel.v1.MsgRecvPacket", "/ibc.core.channel.v1.MsgAcknowledgement", "/ibc.core.client.v1.MsgUpdateClient", "/ibc.applications.transfer.v1.MsgTransfer", "/ibc.core.channel.v1.MsgTimeout", "/ibc.core.channel.v1.MsgTimeoutOnClose",]'

    pawn.console.debug("Start DEBUG mode")
    pawn.set(
        app_name="initialize",
        PAWN_LOGGER=dict(
            log_path=f"{os.environ.get('LOG_PATH')}",
            stdout=True,
        )
    )
    config_files = ["config_", "app_", "client_"]
    for conf in config_files:
        toml_parser(conf, dry_run)


if __name__ == "__main__":
    main()
