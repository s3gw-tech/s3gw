#!/usr/bin/env python3

"""
A s3-tests runner tailored to s3gw containers with parallel execution,
result and log gathering
"""

import logging

import analyze
import click
import runner
import to_sqlite

LOG = logging.getLogger("s3tr")


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.option("--debug/--no-debug", default=False)
def s3tr(debug):
    """
    s3tr - s3gw project s3tests runner
    """
    loglevel = [logging.INFO, logging.DEBUG][int(debug)]
    logging.basicConfig(
        level=loglevel, format="%(name)s: %(message)s", datefmt="[%Y-%m-%d %H:%M:%S]"
    )
    logging.getLogger("urllib3.connectionpool").setLevel(logging.WARN)
    logging.getLogger("docker.auth").setLevel(logging.INFO)
    logging.getLogger("docker.utils.config").setLevel(logging.INFO)
    logging.getLogger("boto").setLevel(logging.WARN)


if __name__ == "__main__":
    s3tr.add_command(runner.run)
    s3tr.add_command(to_sqlite.to_sqlite)
    s3tr.add_command(to_sqlite.datasette)
    s3tr.add_command(analyze.analyze)
    s3tr()
