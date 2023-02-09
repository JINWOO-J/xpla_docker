#!/usr/bin/env python3
from pawnlib.config import pawnlib_config as pawn
from pawnlib.typing import FlatDict, str2bool, return_guess_type, guess_type
from pawnlib.output import open_file, dump, classdump, is_file
import toml
import os


def get_config_toml(key=None):
    default_dir = f"{os.environ.get('DATA_DIR')}/config"
    return f"{default_dir}/{key[:-1]}.toml"


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
                v = return_guess_type(v)
                if old_value != v and dry_run == False:
                    pawn.app_logger.info(f"key={config_key}, old={old_value}, new={v}, config_file={config_filename}")
                    config_flat_dict[config_key] = v
                    is_updated = "changed"

                pawn.console.debug(f"[{is_updated.upper()}] key={config_key}({type(config_key)}), "
                                   f"old={old_value}({type(old_value)}), new={v}({type(v)}), config_file={config_filename}")

        if is_updated == "changed":
            with open(config_filename, "w") as toml_file:
                toml.dump(config_flat_dict.as_dict(), toml_file)
    else:
        pawn.app_logger.info(f"{config_filename} not found")


def main(dry_run=False):
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
