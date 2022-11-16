#!/usr/bin/env python3
from pawnlib.config import pawnlib_config as pawn
from pawnlib.typing.converter import FlatDict, str2bool
from pawnlib.output import open_file, dump, classdump, is_file
import toml
import os


def get_config_toml(key=None):
    default_dir = f"{os.environ.get('DATA_DIR')}/config"
    return f"{default_dir}/{key[:-1]}.toml"


def toml_parser(config_prefix="config_"):
    config_filename = get_config_toml(config_prefix)
    is_updated = False
    if is_file(config_filename):
        config_toml = open_file(config_filename)
        config = toml.loads(config_toml)
        config_flat_dict = FlatDict(config, delimiter="__")
        # pawn.console.log(f"[START] Change the config file with environment values - {config_filename}")
        for k, v in os.environ.items():
            if k.startswith(config_prefix):
                config_key = k.replace(config_prefix, "")
                old_value = config_flat_dict.get(config_key)
                if isinstance(old_value, bool):
                    v = str2bool(v)
                elif isinstance(old_value, int):
                    v = int(v)
                elif isinstance(old_value, float):
                    v = float(v)
                if old_value != v:
                    pawn.app_logger.info(f"key={config_key}, old={old_value}, new={v}, config_file={config_filename}")
                    config_flat_dict[config_key] = v
                    is_updated = True

        if is_updated:
            with open(config_filename, "w") as toml_file:
                toml.dump(config_flat_dict.as_dict(), toml_file)
    else:
        pawn.app_logger.info(f"{config_filename} not found")


if __name__ == "__main__":
    pawn.set(
        app_name="initialize",
        PAWN_LOGGER=dict(
            log_path=f"{os.environ.get('LOG_PATH')}",
            stdout=True,
        )
    )
    config_files = ["config_", "app_", "client_"]
    for conf in config_files:
        toml_parser(conf)
