#!/usr/bin/env python3
# Copyright 2023 SUSE LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import binascii
import json
import logging
import re
from datetime import datetime
from pathlib import Path
from tempfile import TemporaryDirectory

import click
import git
import github
import github.Commit
import github.Repository
import requests
import rich
import rich.box
from dateutil.parser import parse as parse_date
from git.repo import Repo
from github import Github
from packaging import version
from rich.console import Console
from rich.logging import RichHandler
from rich.prompt import Prompt
from rich.table import Table

REPOS = {
    "s3gw": "aquarist-labs/s3gw",
    "ui": "aquarist-labs/s3gw-ui",
    "charts": "aquarist-labs/s3gw-charts",
    "ceph": "aquarist-labs/ceph",
}

LOG = logging.getLogger("vogon-report")


class GitRefName:
    """
    Base class for git references like branches or tags.
    Used as a string type wrapper to prevent calling functions
    with tags where branches are needed and vice versa.
    """

    def __init__(self, name: str):
        self._name = name

    def __str__(self):
        return str(self._name)

    def __repr__(self):
        return f"{self.__class__.__qualname__}({self._name})"

    @property
    def name(self):
        return self._name


class GitTagName(GitRefName):
    pass


class GitBranchName(GitRefName):
    pass


def guess_next_version(api) -> str:
    """
    Make a guess what the next version number will be
    """
    s3gw = api.get_repo("aquarist-labs/s3gw")
    last = max(
        [
            version.Version(match.group(1))
            for r in s3gw.get_releases()
            if (match := re.search(r"v(\d+\.\d+\.\d+)$", r.title))
        ]
    )
    result = f"{last.major}.{last.minor+1}"
    return result


@click.group()
@click.pass_context
@click.option(
    "--state",
    type=click.Path(
        exists=False,
        file_okay=True,
        dir_okay=False,
        resolve_path=True,
        allow_dash=False,
        path_type=Path,
    ),
    required=True,
)
def release(ctx, state: Path):
    ctx.ensure_object(dict)
    loglevel = logging.INFO
    logging.basicConfig(
        level=loglevel,
        format="%(message)s",
        datefmt="[%Y-%m-%d %H:%M:%S]",
        handlers=[RichHandler(rich_tracebacks=True)],
    )
    logging.getLogger("urllib3.connectionpool").setLevel(logging.WARN)
    logging.getLogger("docker.auth").setLevel(logging.INFO)
    logging.getLogger("docker.utils.config").setLevel(logging.INFO)

    try:
        with open(state) as fd:
            j = json.load(fd)
            ctx.obj = j
    except Exception:
        ctx.obj = {"fn": str(state.absolute())}


def save_ctx(ctx):
    """
    Write context object data to state file
    """
    with open(ctx.obj["fn"], "w") as fd:
        json.dump(ctx.obj, fd)


@release.command()
@click.pass_context
@click.option(
    "--s3gw",
    type=click.Path(
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
        allow_dash=False,
        path_type=Path,
    ),
    required=True,
    help="local aquarist-labs/s3gw repo clone",
)
@click.option(
    "--s3gw-ceph",
    type=click.Path(
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
        allow_dash=False,
        path_type=Path,
    ),
    required=True,
    help="local aquarist-labs/ceph repo clone",
)
@click.option(
    "--s3gw-ui",
    type=click.Path(
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
        allow_dash=False,
        path_type=Path,
    ),
    required=True,
    help="local aquarist-labs/s3gw-ui repo clone",
)
@click.option(
    "--s3gw-charts",
    type=click.Path(
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
        allow_dash=False,
        path_type=Path,
    ),
    required=True,
    help="local aquarist-labs/s3gw-charts repo clone",
)
@click.option(
    "--github-token",
    required=True,
    type=str,
    help="Github token. (Create on GH: Settings / Developer settings "
    "/ Personal access tokens (classic)). Written to state file.",
)
def start(
    ctx,
    s3gw: Path,
    s3gw_ceph: Path,
    s3gw_ui: Path,
    s3gw_charts: Path,
    github_token: str,
):
    "Do this first"
    console = Console()
    repos = {
        "s3gw": Repo(s3gw.absolute()),
        "ceph": Repo(s3gw_ceph.absolute()),
        "ui": Repo(s3gw_ui.absolute()),
        "charts": Repo(s3gw_charts.absolute()),
    }

    github_api = Github(github_token)
    print(f"Hello {github_api.get_user().name}")

    version = Prompt.ask(
        "New version MAJOR.MINOR?", default=guess_next_version(github_api)
    )
    patch = Prompt.ask("New version PATCH?", default="0")
    branch_name = GitBranchName(f"s3gw-v{version}")
    version = f"{version}.{patch}"

    ctx.obj["wd"] = {k: str(v.working_dir) for k, v in repos.items()}
    ctx.obj["version"] = version
    ctx.obj["release_branch"] = str(branch_name)
    ctx.obj["github_token"] = github_token
    save_ctx(ctx)

    console.print(ctx.obj)
    console.print("Everything set up. You may want to run branch next")


@release.command()
@click.pass_context
def branch(ctx):
    """
    Create release branches (interactive). Do this once. (ex: s3gw-v0.42)
    """
    console = Console()
    branch_name = GitBranchName(ctx.obj["release_branch"])
    assert ctx.obj.get("github_token", False), ctx.obj
    assert ctx.obj.get("version", False), ctx.obj
    assert not ctx.obj.get("released", False), ctx.obj
    assert not ctx.obj.get("branched", False), ctx.obj
    assert ctx.obj.get(["wd"], False)

    github_api = Github(ctx.obj["github_token"])
    refspecs = {}

    actions_table = Table(box=rich.box.SIMPLE)
    actions_table.add_column("Repo")
    actions_table.add_column("Branch")
    actions_table.add_column("Last")
    actions_table.add_column("URL")

    for name, gh in REPOS.items():
        repo = github_api.get_repo(gh)
        def_branch = repo.get_branch(repo.default_branch)
        try:
            pr = def_branch.commit.get_pulls()[0]
            last_hint = f"{pr.title} {str(pr.closed_at)}"
        except IndexError:
            last_hint = def_branch.commit.sha

        refspecs[name] = f"{def_branch.commit.sha}:refs/heads/{branch_name.name}"
        actions_table.add_row(
            repo.full_name,
            def_branch.name,
            last_hint,
            f"[link={def_branch.commit.html_url}]{def_branch.commit.html_url}[/link]",
        )

    console.print(
        f"Do you want to branch to following off to [bold]{branch_name.name}[/bold]"
    )
    console.print(actions_table)
    if Prompt.ask(
        "Enter number of branches to create:",
        choices=[str(len(refspecs)), "no"],
        default="no",
    ) == str(len(refspecs)):
        for name, wd in ctx.obj["wd"].items():
            git_r = Repo(wd)
            gh_r = github_api.get_repo(REPOS[name])

            if "aquarist" not in [r.name for r in git_r.remotes]:
                console.print(f"Setting remote aquarist to {str(git_r)}")
                git_r.create_remote("aquarist", gh_r.ssh_url)

            remote = git_r.remote("aquarist")
            console.print(f"Updating remote {str(remote)} in {git_r}")
            remote.update()
            console.print(f"Pushing: {refspecs[name]}")
            remote.push(refspecs[name])

    ctx.obj["branched"] = True
    save_ctx(ctx)


@release.command()
@click.pass_context
def increment_patch_version(ctx):
    """
    (major.minor.patch++)
    """
    assert not ctx.obj.get("released", False), ctx.obj
    assert ctx.obj.get("version", False), ctx.obj
    assert ctx.obj.get("branched", False), ctx.obj

    current = version.Version(ctx.obj["version"])
    next = f"{current.major}.{current.minor}.{current.micro+1}"
    ctx.obj["version"] = next
    save_ctx(ctx)


def collect_repo_tag_information(
    api: Github, repos: list[str], release_branch: GitBranchName
) -> tuple[dict[str, github.Commit.Commit], Table]:
    """
    Collect latest $release_branch commit data for $repos into
    a dict indexed by repos and a rich table for printing.
    """
    tags = {}
    table = Table(box=rich.box.SIMPLE)

    table.add_column("Repo")
    table.add_column("Commit")
    table.add_column("Last")
    table.add_column("URL")

    for name in repos:
        gh_r = api.get_repo(REPOS[name])
        gh_branch = gh_r.get_branch(release_branch.name)

        git_commit = gh_branch.commit.commit
        summary = git_commit.message.split("\n")[0]
        last_hint = f"{summary} {str(git_commit.author.date)}"
        try:
            pr = gh_branch.commit.get_pulls()[0]
            last_hint += f" PR: {pr.title}"
        except IndexError:
            pass

        table.add_row(
            gh_r.full_name,
            gh_branch.commit.sha,
            last_hint,
            f"[link={gh_branch.commit.html_url}]{gh_branch.commit.html_url}[/link]",
        )
        tags[name] = gh_branch.commit
    return tags, table


def tag_and_push(
    git_r: Repo, tag_name: GitTagName, commit: github.Commit.Commit, message: str
) -> None:
    """
    Add tag to git repo $git_r with $tag_name pointing to commit $commit.
    Use annotated tags with $message
    """
    try:
        new_tag = git_r.create_tag(
            tag_name.name,
            ref=commit.sha,
            message=message,
            sign=True,
        )
        git_r.remote("aquarist").push(new_tag.name)
        LOG.info(f"Tagged and pushed: {str(git_r)} {str(tag_name)} {str(commit)}")
    except git.GitCommandError as e:
        if "already exists" in e.stderr:
            LOG.error(f"Repo {str(git_r)}: tag {str(tag_name)} already exists")
        else:
            raise e


def update_s3gw_submodules(
    console: Console,
    gh_r: github.Repository.Repository,
    git_r: Repo,
    tags: dict[str, github.Commit.Commit],
    release_tag: GitTagName,
    release_branch: GitBranchName,
    commit_message: str,
) -> None:
    "Update aquarist-labs/s3gw repo submodules to $tags. Ask before pushing"
    with TemporaryDirectory() as td:
        LOG.info(
            f"Cloning {str(gh_r)} from {gh_r.ssh_url} "
            f"branch {str(release_branch)} to {td}"
        )

        tmp_r = Repo.clone_from(gh_r.ssh_url, td, branch=release_branch.name, depth=1)
        with tmp_r.config_writer() as cw:
            email = git_r.config_reader().get_value("user", "email")
            signingkey = git_r.config_reader().get_value("user", "signingkey")

            assert email
            assert signingkey

            cw.add_section("user")
            cw.set_value("user", "email", email)
            cw.set_value("user", "signingkey", signingkey)

            cw.add_section("commit")
            cw.set("commit", "gpgsign", "true")

        for name in tags.keys():
            submod = tmp_r.submodule(name)
            submod.binsha = binascii.a2b_hex(tags[name].sha)
            tmp_r.index.add([submod])

        tmp_r.index.write()
        try:
            tmp_r.git.commit(
                "-S",
                f"--gpg-sign={signingkey}",
                "-m",
                f"Submodules for {commit_message}",
            )
        except git.GitCommandError as e:
            LOG.exception("committing submodule update failed")
            if "Your branch is up to date with 'origin/s3gw" in e.stdout:
                if (
                    Prompt.ask(
                        "No submodule changes. Continue with tag and push?",
                        default="no",
                        choices=["yes", "no"],
                    )
                    == "no"
                ):
                    return
            else:
                raise e

        head = tmp_r.head.commit
        tag = tmp_r.create_tag(
            release_tag.name,
            ref=head.hexsha,
            message=commit_message,
            sign=True,
        )

        table = Table(box=rich.box.SIMPLE, title="Submodule Update Commit")
        table.add_row("sha", head.hexsha)
        table.add_row("parent", repr(head.parents))
        table.add_row("summary", str(head.summary))
        table.add_row("author", repr(head.author))
        table.add_row("committer", repr(head.committer))
        table.add_row("gpg", head.gpgsig)
        console.print(table)
        console.print("\n")
        console.print(f"Tag: {str(tag)}")
        if (
            Prompt.ask(
                f"Push commit {str(head)} and tag {str(tag)} to {str(gh_r)}?",
                default="no",
                choices=["yes", "no"],
            )
            == "yes"
        ):
            remote = tmp_r.remote("origin")
            remote.push(f"{head.hexsha}:{release_branch.name}")
            remote.push(tag.name)


@release.command()
@click.pass_context
def create_candidate(ctx):
    """
    Create release candidate (interactive). Repos affected: ceph, s3gw-ui, s3gw
    """
    console = Console()
    assert ctx.obj.get("version", False), ctx.obj
    assert re.match(r"\d+\.\d+\.\d+", ctx.obj["version"])
    assert not ctx.obj.get("released", False)
    assert ctx.obj.get("branched", False), ctx.obj
    assert ctx.obj.get("github_token", False), ctx.obj

    github_api = Github(ctx.obj["github_token"])

    repos = ["ceph", "ui"]
    version = ctx.obj["version"]
    candidate_num = ctx.obj.get("rc", 0) + 1
    release_branch = GitBranchName(ctx.obj["release_branch"])
    tag_name = GitTagName(f"s3gw-v{version}-rc{candidate_num}")
    commit_message = f"Release Candidate {candidate_num} for v{version}"

    tags, table = collect_repo_tag_information(github_api, repos, release_branch)
    console.print(
        f"Do you want to create tag {str(tag_name)} and push the following tags?"
    )
    console.print(table)

    if Prompt.ask(
        "Enter number of tags to create:",
        choices=[str(len(tags)), "no"],
        default="no",
    ) == str(len(tags)):
        for name, commit in tags.items():
            git_r = Repo(ctx.obj["wd"][name])
            tag_and_push(git_r, tag_name, commit, commit_message)

        s3gw_gh_r = github_api.get_repo(REPOS["s3gw"])
        s3gw_git_r = Repo(ctx.obj["wd"]["s3gw"])
        update_s3gw_submodules(
            console,
            s3gw_gh_r,
            s3gw_git_r,
            tags,
            tag_name,
            release_branch,
            commit_message,
        )
        candidate_num += 1
        ctx.obj["rc"] = candidate_num
        save_ctx(ctx)


@release.command()
@click.pass_context
def create_release(ctx):
    """
    Create release (interactive). Repos affected: ceph, s3gw-ui, s3gw-charts, s3gw
    """
    console = Console()

    assert ctx.obj.get("github_token", False), ctx.obj
    assert re.match(r"\d+\.\d+\.\d+", ctx.obj["version"])
    assert not ctx.obj.get("released", False)
    assert ctx.obj.get("branched", False), ctx.obj

    github_api = Github(ctx.obj["github_token"])
    repos = ["ceph", "ui", "charts"]
    release_branch = GitBranchName(ctx.obj["release_branch"])
    version = ctx.obj["version"]
    tag_name = GitTagName(f"s3gw-v{version}")
    s3gw_repo_tag = GitTagName(f"v{version}")
    commit_message = f"Release v{version}"

    tags, table = collect_repo_tag_information(github_api, repos, release_branch)
    console.print(
        f"Do you want to create tag and push [b]{str(tag_name)}[/b] to the following?"
    )
    console.print(f"Commit message: [b]{commit_message}[/b]")
    console.print(table)

    if Prompt.ask(
        "Enter number of tags to create:",
        choices=[str(len(tags)), "no"],
        default="no",
    ) == str(len(tags)):
        for name, commit in tags.items():
            git_r = Repo(ctx.obj["wd"][name])
            tag_and_push(git_r, tag_name, commit, commit_message)

        s3gw_gh_r = github_api.get_repo(REPOS["s3gw"])
        s3gw_git_r = Repo(ctx.obj["wd"]["s3gw"])
        update_s3gw_submodules(
            console,
            s3gw_gh_r,
            s3gw_git_r,
            tags,
            s3gw_repo_tag,
            release_branch,
            commit_message,
        )
        ctx.obj["released"] = True
        save_ctx(ctx)


def list_quay_tags(repo):
    return requests.get(
        f"https://quay.io/api/v1/repository/s3gw/{repo}"
        f"/tag/?limit=100&page=1&onlyActiveTags=true"
    ).json()


def list_artifacthub_repo():
    return requests.get("https://artifacthub.io/api/v1/packages/helm/s3gw/s3gw").json()


@release.command()
@click.pass_context
def sanity_checks(ctx):
    """
    Is everything released properly?
    """

    console = Console()
    assert ctx.obj.get("github_token", False), ctx.obj
    assert re.match(r"\d+\.\d+\.\d+", ctx.obj["version"])
    assert ctx.obj.get("released", False)
    assert ctx.obj.get("branched", False), ctx.obj

    github_api = Github(ctx.obj["github_token"])
    version = ctx.obj["version"]
    version_tag = f"v{ctx.obj['version']}"
    s3gw_repo_tag = GitTagName(f"v{version}")

    for repo in ["s3gw", "s3gw-ui"]:
        quay_repo = list_quay_tags(repo)
        quay_tags = sorted(
            quay_repo["tags"],
            key=lambda x: parse_date(x["last_modified"]),
            reverse=True,
        )

        table = Table(box=rich.box.SIMPLE, title=f"Recent {repo} Quay Tags")
        table.add_column("Tag")
        table.add_column("Last Mod")
        table.add_column("Size")
        table.add_column("Digest")
        table.add_column("URL")
        for tags in quay_tags[:5]:
            table.add_row(
                tags["name"],
                str(parse_date(tags["last_modified"])),
                str(tags["size"]),
                tags["manifest_digest"],
            )
        console.print(table)
        console.print(f"URL: https://quay.io/repository/s3gw/{repo}?tab=tags")
        console.print("\n")

        indexed = {t["name"]: t for t in quay_tags}

        if not indexed.get(version_tag):
            console.print(
                f":warning:  No release version tag {version_tag}", style="magenta"
            )
        try:
            if (
                indexed["latest"]["manifest_digest"]
                != indexed[version_tag]["manifest_digest"]
            ):
                console.print(
                    ":warning:  Latest digest != release digest", style="magenta"
                )
        except Exception:
            LOG.exception("things we need to check dont exists. :(")

    console.print("\n")
    artifacthub_repo = list_artifacthub_repo()
    arti_versions = sorted(
        artifacthub_repo["available_versions"],
        key=lambda x: datetime.fromtimestamp(x["ts"]),
        reverse=True,
    )
    table = Table(box=rich.box.SIMPLE, title="Recent ArtifactHub Versions")
    table.add_column("Version")
    table.add_column("TS")
    for ver in arti_versions[:3]:
        table.add_row(ver["version"], str(datetime.fromtimestamp(ver["ts"])))
    console.print(table)
    console.print("URL: https://artifacthub.io/packages/helm/s3gw/s3gw")
    console.print("\n")

    indexed = {v["version"]: v for v in arti_versions}
    if not indexed.get(version):
        console.print(f":warning:  No release version tag {version}", style="magenta")

    gh_repo = github_api.get_repo("aquarist-labs/s3gw")
    latest = gh_repo.get_latest_release()
    console.print("\n")
    console.print("[r]Github Releases[/r]")
    console.print("\n")
    console.print(
        f"Latest: {latest.title} tag {latest.tag_name} created {str(latest.created_at)}"
    )

    if latest.tag_name != version_tag:
        console.print(
            f":warning:  Latest github release != release {version_tag}",
            style="magenta",
        )

    console.print("\n")
    console.print("[r]Release Notes[/r]")
    console.print("\n")
    for branch in ["main", s3gw_repo_tag]:
        relnote_fn = f"s3gw-v{version}.md"
        relnote = requests.get(
            f"https://raw.githubusercontent.com/aquarist-labs/s3gw/{branch}"
            f"/docs/release-notes/latest"
        )
        if relnote.text == relnote_fn:
            console.print(f"{branch} {relnote_fn} latest link ok")
        else:
            console.print(
                f":warning:  Release notes link wrong {branch} {relnote.text}",
                style="magenta",
            )
        relnote = requests.get(
            f"https://raw.githubusercontent.com/aquarist-labs/s3gw/{branch}"
            f"/docs/release-notes/{relnote_fn}"
        )
        if version_tag in relnote.text:
            console.print(f"{branch} {version_tag} in release note ok")
        else:
            console.print(
                f":warning:  Release note ({branch}) does not contain version",
                style="magenta",
            )
            console.print(relnote.text)


if __name__ == "__main__":
    release(obj={})
