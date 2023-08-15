#!/usr/bin/env python3
"""
Convert s3gw s3 tests runner JSON results
to an SQLite database suitable to Datasette
"""

import configparser
import json
import logging
import pathlib
import tempfile

import click
import sqlite_utils
import uvicorn
import yaml
from datasette.app import Datasette

LOG = logging.getLogger("s3tr")


def get_test_result(result):
    ret = result["test_return"]
    logs = result["container_logs"]
    if "Segmentation fault" in logs:
        return f"{ret}+segfault"
    if "FAILED ceph_assert" in logs:
        return f"{ret}+assertion"
    elif "BUG Unhandled exception" in logs:
        return f"{ret}+unhandled exception"
    elif "end dump of recent events" in logs:
        return f"{ret}+crash"

    return ret


def get_keywords(result, markers):
    if result["test_data"]:
        return markers & frozenset(result["test_data"]["keywords"])
    else:
        return set()


def make_full_results_database(results, pytest_markers, db_path):
    db = sqlite_utils.Database(db_path)
    for i, result in enumerate(results):
        keywords = get_keywords(result, pytest_markers)
        row = {
            "test": result["test"].split("::")[1],
            "result": get_test_result(result),
            "out": result["test_output"],
            "log_container": result["container_logs"],
            "metrics": result["metrics"],
        }
        db["results"].insert(row, pk="test")
        for keyword in keywords:
            db["results_keywords"].insert(
                {"test": row["test"], "keyword": keyword},
                foreign_keys=[("test", "results", "test")],
                pk="id",
            )

        if (i % 50) == 0:
            LOG.info(f"{i}/{len(results)} done")

    db.create_view(
        "results_with_keywords",
        """
       select
         results.test,
         json_group_array(results_keywords.keyword) as keywords, result
       from results inner join results_keywords
       on results.test = results_keywords.test
       group by results.test
    """,
    )
    db["results"].enable_fts(["out", "log_container"])
    db["results"].create_index(["result"])
    db["results_keywords"].create_index(["keyword"])
    db["results_keywords"].create_index(["test"])


def make_comparison_database(results_by_versions, db_path):
    db = sqlite_utils.Database(db_path)
    db["versions"].insert_all(
        [
            {"name": version, "id": index}
            for (version, index), result in results_by_versions.items()
        ],
        pk="id",
    )
    for (_, index), results in results_by_versions.items():
        for result in results:
            db["results"].insert(
                {
                    "test": result["test"].split("::")[1],
                    "result": get_test_result(result),
                    "version_id": index,
                },
                pk="id",
                foreign_keys=("version_id", "versions"),
            )


@click.group()
def to_sqlite():
    """
    Convert JSON test results into SQLite databases
    """
    pass


@click.group()
def datasette():
    """
    Open results in datasette
    """
    pass


@to_sqlite.command()
@click.option(
    "--pytest-ini",
    envvar="PYTEST_INI",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.argument(
    "db_path",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.argument("input", type=click.File("r"))
def convert(pytest_ini, db_path, input):
    """
    Create sqlite database with full logs and test output from a
    single testrun JSON file
    """
    results = json.load(input)
    ini_parser = configparser.ConfigParser()
    ini_parser.read(pytest_ini)
    markers = frozenset(ini_parser["pytest"]["markers"].split())
    make_full_results_database(results, markers, db_path)


@datasette.command()
@click.option(
    "--pytest-ini",
    envvar="PYTEST_INI",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.option(
    "--datasette-metadata",
    envvar="DATASETTE_METADATA",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.argument("input", type=click.File("r"))
def serve(pytest_ini, datasette_metadata, input):
    """
    Open full results for a single run in datasette
    """
    results = json.load(input)
    ini_parser = configparser.ConfigParser()
    ini_parser.read(pytest_ini)
    markers = frozenset(ini_parser["pytest"]["markers"].split())
    with open(datasette_metadata) as fp:
        metadata = yaml.safe_load(fp)

    with tempfile.TemporaryDirectory() as tmpdir, open(
        pathlib.Path(tmpdir) / "results.db", "w"
    ) as db_file:
        LOG.info(f"Converting {input} to SQLite {db_file.name}")
        make_full_results_database(results, markers, db_file.name)

        ds = Datasette(files=[db_file.name], metadata=metadata)
        LOG.info(f"Starting datasette {ds}")
        uvicorn.run(ds.app(), host="0.0.0.0", port=8080, lifespan="on", workers=1)


@to_sqlite.command()
@click.option(
    "--pytest-ini",
    envvar="PYTEST_INI",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.argument(
    "db_path",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
)
@click.argument(
    "input_files",
    type=click.Path(
        file_okay=True, dir_okay=False, allow_dash=False, path_type=pathlib.Path
    ),
    required=True,
    nargs=-1,
)
def comparison(pytest_ini, db_path, input_files):
    """
    Create comparison database from result json files
    """
    results_by_versions = {}
    for i, file in enumerate(input_files):
        with open(file) as fp:
            results = json.load(fp)
        results_by_versions[(file.name, i)] = results

    make_comparison_database(results_by_versions, db_path)


if __name__ == "__main__":
    to_sqlite()
