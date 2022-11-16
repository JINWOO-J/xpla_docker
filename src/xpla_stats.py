#!/usr/bin/env python3
import os

from pawnlib.config import pawnlib_config as pawn
from pawnlib.utils.log import AppLogger
from pawnlib.utils.http import jequest, disable_ssl_warnings
from pawnlib.output import *
from pawnlib.typing.converter import str2bool, StackList, is_int
from pawnlib.utils import notify
import argparse
import time
from dotenv import load_dotenv

disable_ssl_warnings()
__version = "0.0.3"


def print_banner():
    print(f'[97m')
    print(f'--------------------------------------------------')
    print(f'\n')
    print(f'             _                                            ')
    print(f'            | |                      _           _        ')
    print(f' _   _ ____ | | _____          ___ _| |_ _____ _| |_  ___ ')
    print(f'( \ / )  _ \| |(____ |        /___|_   _|____ (_   _)/___)')
    print(f' ) X (| |_| | |/ ___ |_______|___ | | |_/ ___ | | |_|___ |')
    print(f'(_/ \_)  __/ \_)_____(_______|___/   \__)_____|  \__|___/ ')
    print(f'      |_|                                                 ')
    print(f'')
    print(f' - Description : This is script')
    print(f' - Version     : {__version}')
    print(f' - Author      : jinwoo')
    print(f'\n')
    print(f'--------------------------------------------------')
    print(f'[0m')


def get_block_info(url):
    res = jequest(f"{url}/status")
    if res.get('json') and res['json'].get('result'):
        sync_info = res['json']['result']['sync_info']
        validator_info = res['json']['result']['validator_info']
        validator_address = validator_info.get('address').lower()

        block_height = int(sync_info['latest_block_height'])
        latest_block_time = sync_info['latest_block_time']
        now_time = time.time()
        # print(pawn.get('last_block'))
        previous_block = pawn.get('last_block').get('height')
        previous_time = pawn.get('last_block').get('time')
        diff_block = block_height - previous_block
        diff_time = now_time - previous_time
        tps = round(diff_block / diff_time, 2)

        message = f"BH: {block_height:,}, TPS: {tps:,}, BlockTime: {latest_block_time}, Validator: {validator_address}"
        f" // catch: {sync_info['catching_up']} diff_time: {round(diff_time, 2)}, prev_bh: {previous_block}"
        if pawn.get('args').verbose:
            pawn.console.log(message)
        else:
            pawn.app_logger.info(message)

        last_block = {
            "height": block_height,
            "time": now_time
        }

        pawn.set(
            last_block=last_block
        )

        if diff_block == 0:
            pawn.increase(fail_count=1)
        else:
            pawn.set(fail_count=0)
        return block_height
    else:
        pawn.increase(fail_count=1)


def get_parser():
    parser = argparse.ArgumentParser(
        description='Command Line Interface for docker',
        fromfile_prefix_chars='@'
    )
    parser.add_argument('-u', '--url', type=str, default="http://localhost:26657")
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument('-i', '--interval', type=int, default=int(os.getenv('STAT_INTERVAL', 10)))
    parser.add_argument('-s', '--stdout', type=str2bool, default=os.getenv('STDOUT', True))

    return parser.parse_args()


def _send_slack(msg_text):
    slack_url = os.environ.get('SLACK_URL')
    if slack_url:
        notify.send_slack(url=slack_url, send_user_name="XPLA", msg_text=msg_text)


def main():

    load_dotenv()
    args = get_parser()
    LOG_DIR = os.getenv("LOG_PATH", f"{get_real_path(__file__)}/logs")
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR)
    APP_NAME = "xpla_stats"
    pawn.set(
        PAWN_LOGGER=dict(
            log_level="INFO",
            stdout_level="INFO",
            log_path=LOG_DIR,
            stdout=args.stdout,
            use_hook_exception=True,
        ),
        PAWN_DEBUG=True,  # Don't use production, because it's not stored exception log.
        app_name=APP_NAME,
        app_data={},
        last_block={
            "height": 0,
            "time": time.time()
        },
        stack_limit=int(os.environ.get('STACK_LIMIT', 100)),
        fail_count=0,
        block_stack=StackList(100),
        args=args
    )
    pawn.console.log(f"{args.url}, interval={args.interval}, LOG_DIR={LOG_DIR}")
    pawn.console.log(pawn.to_dict())

    slack_url = os.environ.get('SLACK_URL')
    pawn.console.log(f"slack_url={slack_url} ")
    pawn.conf()

    _send_slack("START")

    while True:
        try:
            get_block_info(args.url)
            if pawn.get('fail_count') > pawn.get('stack_limit'):
                _send_slack(f"[bold red] fail_count: {pawn.get('fail_count')} > {pawn.get('stack_limit')}")
                pawn.set(fail_count=0)

        except Exception as e:
            pawn.error_logger.error(f"Exception - {e}")
            _send_slack(f"Exception - {e}")
        time.sleep(args.interval)


if __name__ == "__main__":
    try:
        print_banner()
        main()

    except KeyboardInterrupt:
        pawn.console.log("Keyboard Interrupted")
