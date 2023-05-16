#!/usr/bin/env python3

"""
Simple analysis tasks for s3tr JSON results
"""

import json
import logging
import pathlib
import sys

import click
import requests
import rich
from rich.console import Console
from rich.table import Table

LOG = logging.getLogger("s3tr")


@click.group()
def analyze():
    """Analyze s3tr JSON results"""


def get_upstream_list():
    resp = requests.get(
        "https://raw.githubusercontent.com/aquarist-labs/ceph"
        "/s3gw/qa/rgw/store/sfs/tests/fixtures/s3-tests.txt"
    )
    resp.raise_for_status()
    return resp.text


def get_known_good(file=None):
    if file:
        with open(file) as fp:
            data = fp.read().split("\n")
    else:
        data = get_upstream_list().split("\n")

    return frozenset(test for test in data if test and not test.startswith("#"))


@analyze.command()
@click.option(
    "--known-good-file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
)
@click.argument(
    "file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
    nargs=1,
)
def new_failures(known_good_file, file):
    """
    Compare results to known good from latest main branch
    """
    console = Console()

    known_good = get_known_good(known_good_file)
    with open(file) as fp:
        results = json.load(fp)

    results = {result["test"].split("::")[1]: result for result in results}

    success = frozenset(
        (name for name, result in results.items() if result["test_return"] == "success")
    )

    known_good_that_fail_now = known_good - success

    table = Table(box=rich.box.SIMPLE, caption="Known good tests that fail now")
    table.add_column("Test Name")
    table.add_column("Test Result")
    table.add_column("Container Exit")
    for test in known_good_that_fail_now:
        table.add_row(
            test, results[test]["test_return"], results[test]["container_return"]
        )
    console.print(table)
    if len(known_good_that_fail_now) > 0:
        sys.exit(23)


@analyze.command()
@click.option(
    "--known-good-file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
)
@click.argument(
    "file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
    nargs=1,
)
def new_successes(known_good_file, file):
    """
    What to add to s3-tests.txt?
    """
    known_good = get_known_good(known_good_file)
    with open(file) as fp:
        results = json.load(fp)
    results = {result["test"].split("::")[1]: result for result in results}
    success = frozenset(
        (name for name, result in results.items() if result["test_return"] == "success")
    )

    succeeding_not_in_known_good = success - known_good
    print("\n".join(succeeding_not_in_known_good))


def get_result(file, test_name):
    with open(file) as fp:
        results = json.load(fp)
    return next(result for result in results if test_name in result["test"])


def print_result(file, test_name, key):
    result = get_result(file, test_name)
    LOG.info(
        f"Test {result['test']} result "
        f"{result['test_return']} / {result['test_data']['outcome']}"
    )
    print(get_result(file, test_name)[key])


@analyze.command()
@click.argument(
    "file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
    nargs=1,
)
@click.argument(
    "test-name",
    type=str,
    required=True,
    nargs=1,
)
def logs(file, test_name):
    """
    What to add to s3-tests.txt?
    """
    print_result(file, test_name, "container_logs")


@analyze.command()
@click.argument(
    "file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
    nargs=1,
)
@click.argument(
    "test-name",
    type=str,
    required=True,
    nargs=1,
)
def test_out(file, test_name):
    """
    What to add to s3-tests.txt?
    """
    print_result(file, test_name, "test_output")
