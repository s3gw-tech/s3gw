#!/usr/bin/env python3

"""
Simple analysis tasks for s3tr JSON results
"""

import csv
import json
import logging
import pathlib
import sys

import click
import rich
from rich.console import Console
from rich.table import Table

LOG = logging.getLogger("s3tr")


@click.group()
def analyze():
    """Analyze s3tr JSON results"""


def get_excuses(file):
    result = {}
    with open(file) as fp:
        csvreader = csv.reader(fp, delimiter=";")
        for row in csvreader:
            result[row[0]] = {
                "url": row[1],
                "excuse": row[2],
            }
    return result


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
    "excuses-file",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=False,
    nargs=1,
)
def summary(file, excuses_file):
    """
    Compare results to known good from latest main branch
    """
    console = Console()
    if excuses_file:
        excuses = get_excuses(excuses_file)
    else:
        excuses = None

    with open(file) as fp:
        results = json.load(fp)

    results = {result["test"].split("::")[1]: result for result in results}
    failures = frozenset(
        (name for name, result in results.items() if result["test_return"] != "success")
    )
    successes = frozenset(
        (name for name, result in results.items() if result["test_return"] == "success")
    )

    table = Table(box=rich.box.SIMPLE, title="S3 Test Stats")
    table.add_column("")
    table.add_column("")
    table.add_row("Failed tests", str(len(failures)))
    table.add_row("Successful tests", str(len(successes)))
    table.add_row("Total tests", str(len(results)))
    if excuses:
        table.add_row("Tests OK to fail", str(len(excuses)))

    if not excuses:
        sys.exit(0)

    failures_that_must_not_be = failures - excuses.keys()
    new_successes = excuses.keys() & successes
    table.add_row("Failures, not excused", str(len(failures_that_must_not_be)))
    table.add_row("Successes, excused", str(len(new_successes)))
    console.print(table)

    if failures_that_must_not_be:
        min_width_test = max(len(test) for test in failures_that_must_not_be)
        table = Table(box=rich.box.SIMPLE, title="Failures not in excuse file")
        table.add_column("Test Name", min_width=min_width_test)
        table.add_column("Test Result")
        table.add_column("Container Exit")
        for test in sorted(failures_that_must_not_be):
            table.add_row(
                test, results[test]["test_return"], results[test]["container_return"]
            )
        console.print(table, soft_wrap=True)

    if new_successes:
        min_width_url = max(len(excuses[test]["url"]) for test in new_successes)
        min_width_test = max(len(test) for test in new_successes)
        min_width_excuse = 20
        min_width_total = max(120, min_width_url + min_width_test + min_width_excuse)
        table = Table(
            box=rich.box.SIMPLE,
            title="Tests in excuse file no longer failing",
            expand=True,
            width=min_width_total,
        )
        table.add_column("Test Name", min_width=min_width_test)
        table.add_column("URL", min_width=min_width_url)
        table.add_column("Excuse", min_width=min_width_excuse)
        for test in sorted(new_successes):
            table.add_row(test, excuses[test]["url"], excuses[test]["excuse"])
        console.print(table, soft_wrap=True)
        console.print("Please remove no longer failing tests from excuse file")

    if len(failures_that_must_not_be) > 0 or len(new_successes) > 0:
        console.print("💥")
        sys.exit(23)
    else:
        console.print("🥳")


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
