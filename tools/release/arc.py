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

import re
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Iterable, Literal

import click
import gql
import rich.box
from git import Commit as GitCommit
from git import Reference as GitReference
from git import RemoteProgress as GitRemoteProgress
from git.repo import Repo as GitRepo
from gql.transport.requests import RequestsHTTPTransport
from pydantic import BaseModel
from rich.console import Console
from rich.progress import Progress
from rich.progress import TaskID as ProgressTaskID
from rich.prompt import Prompt
from rich.table import Table

console = Console()


#
# Errors
#


class ArcError(Exception):
    _msg: str | None

    def __init__(self, msg: str | None = None) -> None:
        self._msg = msg

    @property
    def msg(self) -> str:
        return "Unknown Error" if self._msg is None else self._msg

    def __repr__(self) -> str:
        return f"{self.__class__.__qualname__}: {self.msg}"

    def __str__(self) -> str:
        return self.__repr__()


class WorkspaceExistsError(ArcError):
    def __init__(self, ws: Path | str) -> None:
        super().__init__(str(ws))


def error(*args: Any) -> None:
    console.print("Error:", *args, style="bold red")


def success(msg: str) -> None:
    console.print("Success:", msg, style="bold green")


def warn(msg: str) -> None:
    console.print("Warning:", msg, style="bold dark_orange")


def info(*args: Any) -> None:
    console.print("Info:", *args, style="bold cyan")


#
# GQL
#


class ProjectItem(BaseModel):
    number: int
    title: str
    repository: str
    state: str
    item_type: str


def get_project_items(token: str, version: str) -> list[ProjectItem]:

    transport = RequestsHTTPTransport(
        "https://api.github.com/graphql", headers={"Authorization": f"Bearer {token}"}
    )
    client = gql.Client(transport=transport)

    def get_items(cursor: str = "") -> dict[str, Any]:
        query = gql.gql(
            """
query getItems($cursor: String!) {
  repository(owner:"aquarist-labs", name:"s3gw") {
    projectV2(number: 5) {
      items(first: 100, after: $cursor) {
        pageInfo {
          hasNextPage
          endCursor
          startCursor
        }
        nodes {
          fieldValueByName(name:"Milestone"){
            ...on ProjectV2ItemFieldMilestoneValue {
              milestone {
                id
                title
              }
            }
            __typename
          }
          id
          databaseId
          content {
            __typename
            ... on Issue {
              title
              number
              state
              repository {
                owner {
                  login
                }
                name
              }
            }
            ... on PullRequest {
              title
              number
              state
              repository {
                owner {
                  login
                }
                name
              }
            }
          }
        }
      }
    }
  }
}
            """
        )
        return client.execute(  # pyright: ignore[reportUnknownMemberType]
            query, variable_values={"cursor": cursor}
        )

    issues: list[ProjectItem] = []
    next = ""
    while True:
        res = get_items(next)
        # console.print(res)
        items = res["repository"]["projectV2"]["items"]
        pageinfo = items["pageInfo"]
        nodes = items["nodes"]

        for n in nodes:
            fields = n["fieldValueByName"]
            if fields is None:
                continue
            milestone = fields["milestone"]
            if milestone["title"] != f"v{version}":
                continue

            c = n["content"]
            # console.print(c)
            repo = c["repository"]
            issues.append(
                ProjectItem(
                    number=c["number"],
                    title=c["title"],
                    state=c["state"],
                    item_type=c["__typename"],
                    repository=f"{repo['owner']['login']}/{repo['name']}",
                )
            )

        # console.print(f"Page Info: ", pageinfo)
        if not pageinfo["hasNextPage"]:
            break
        next = pageinfo["endCursor"]

    # console.print(issues)
    return issues


#
# State
#


ArcRepoNames = Literal["s3gw"] | Literal["ceph"] | Literal["ui"] | Literal["charts"]


class ArcReleaseStatus(Enum):
    NONE = "none"
    STARTED = "started"
    BRANCHED = "branched"
    INPROGRESS = "in-progress"
    COMMITTED = "committed"
    DONE = "done"


class ArcStateRepo(BaseModel):
    owner: str
    repo: str
    path: Path
    main_branch: str
    release_branch_pattern: str
    release_tag_pattern: str
    registry: str


class ArcStateConfig(BaseModel):
    user_name: str
    user_email: str
    user_key: str
    github_token: str


class ArcRepoReleaseState(BaseModel):
    status: ArcReleaseStatus


class ArcStateRelease(BaseModel):
    version: str
    repos: dict[ArcRepoNames, ArcRepoReleaseState]


class ArcState(BaseModel):
    repos: dict[ArcRepoNames, ArcStateRepo]
    config: ArcStateConfig
    release: ArcStateRelease | None


#
# Repositories
#


class GitProgress(GitRemoteProgress):
    _progress: Progress
    _taskid: ProgressTaskID

    def __init__(self, progress: Progress, taskid: ProgressTaskID) -> None:
        super().__init__()
        self._progress = progress
        self._taskid = taskid

    def update(
        self,
        op_code: int,
        cur_count: str | float,
        max_count: str | float | None = None,
        message: str = "",
    ) -> None:
        max: float | None = None
        if max_count is not None:
            max = float(max_count) if isinstance(max_count, str) else max_count
        cnt = float(cur_count) if isinstance(cur_count, str) else cur_count

        if op_code % 2 != 0:
            self._progress.start_task(self._taskid)
            # this is a new step start
            self._progress.update(self._taskid, total=max, completed=cnt)
        else:
            self._progress.update(self._taskid, completed=cnt)


class RepoStatusState(Enum):
    MATCH = "match"
    DIVERGED = "diverged"
    AHEAD = "ahead"
    BEHIND = "behind"


class RepoStatus(BaseModel):
    cur_head: GitReference
    rem_head: GitReference
    state: RepoStatusState

    class Config:
        arbitrary_types_allowed = True


def _make_version_abs(
    major: str | int, minor: str | int, patch: str | int, rc: str | int
) -> int:
    return (
        int(major) * 10**9
        + int(minor) * 10**6
        + int(patch) * 10**3
        + int(rc) * 10**0
    )


class ReleaseTagInfo(BaseModel):
    name: str
    version: str

    @property
    def version_abs(self) -> int:
        p = r"(\d+)\.(\d+)\.(\d+)(?:-rc(\d+))?"  # match vX.Y.Z(-rcN)
        m = re.match(p, self.version)
        if m is None:
            raise ArcError(f"wrong tag version: {self.version}")

        g = m.groups()
        if len(g) != 4:
            raise ArcError(f"wrong number of version parts: {g}")

        major, minor, patch, rc = g
        rc = rc if rc is not None else 100

        return _make_version_abs(major, minor, patch, rc)


class ReleaseInfo(BaseModel):
    name: str
    version: str
    tags: list[ReleaseTagInfo]

    @property
    def version_abs(self) -> int:
        p = r"^(\d+).(\d+)$"
        m = re.match(p, self.version)
        if m is None or len(m.groups()) != 2:
            raise ArcError(f"wrong version format: {self.version}")

        major, minor = m.groups()
        return _make_version_abs(major, minor, 100, 100)


class ArcRepository:
    _config: ArcStateConfig
    _repo: ArcStateRepo
    _git: GitRepo | None

    def __init__(self, config: ArcStateConfig, repo: ArcStateRepo) -> None:
        self._config = config
        self._repo = repo
        self._git = None

        if self._repo.path.exists():
            assert self._repo.path.is_dir()
            self._git = GitRepo(self._repo.path)

    @property
    def full_name(self):
        return f"{self._repo.owner}/{self._repo.repo}"

    def sync(self) -> None:

        if self._git is None:
            self._git = self._clone()

        assert self._git is not None

        # set config values
        w = self._git.config_writer()
        w.set_value("user", "name", self._config.user_name)
        w.set_value("user", "email", self._config.user_email)
        w.set_value("user", "signingKey", self._config.user_key)
        w.set_value("commit", "gpgSign", "true")
        w.write()

        # update remotes
        self._update_remote()

    def _clone(self) -> GitRepo:
        url = f"git+ssh://git@github.com/{self._repo.owner}/{self._repo.repo}"

        with Progress() as progress:
            task = progress.add_task(
                f"clone {self._repo.owner}/{self._repo.repo}...",
                total=None,
                start=False,
            )
            return GitRepo.clone_from(  # type: ignore
                url,
                self._repo.path,
                GitProgress(progress, task),  # pyright: ignore[reportGeneralTypeIssues]
            )

    def _update_remote(self) -> None:
        assert self._git is not None
        with console.status(f"update {self._repo.owner}/{self._repo.repo}..."):
            self._git.remote().update()

    def _maybe_pull_main(self) -> None:
        assert self._git is not None

        pass

    def _find_head(
        self, refs: Iterable[GitReference], name: str
    ) -> GitReference | None:
        for r in refs:
            if r.name == name:
                return r
        return None

    def _get_head(self, name: str, remote: bool) -> GitReference | None:
        assert self._git is not None

        return (
            self._find_head(self._git.references, name)
            if not remote
            else self._find_head(self._git.remote().refs, f"origin/{name}")
        )

    def check_status(self) -> RepoStatus:
        assert self._git is not None

        main = self._get_head(self._repo.main_branch, remote=False)
        assert main is not None

        remote = self._get_head(main.name, remote=True)
        assert remote is not None

        main_commit: GitCommit = main.commit
        remote_commit: GitCommit = remote.commit

        state: RepoStatusState = RepoStatusState.MATCH
        if main_commit.hexsha != remote_commit.hexsha:
            if self._git.is_ancestor(main_commit, remote_commit):
                state = RepoStatusState.BEHIND
            elif self._git.is_ancestor(remote_commit, main_commit):
                state = RepoStatusState.AHEAD
            else:
                state = RepoStatusState.DIVERGED

        return RepoStatus(cur_head=main, rem_head=remote, state=state)

    def get_releases(self) -> dict[str, ReleaseInfo]:
        assert self._git is not None

        releases: dict[str, ReleaseInfo] = {}

        def _find_all(names: Iterable[str], pattern: str) -> list[tuple[str, str]]:
            lst: list[tuple[str, str]] = []
            for n in names:
                m = re.match(pattern, n)
                if m is None:
                    continue
                lst.append((n, m.group(1)))
            return lst

        tags = _find_all(
            [t.name for t in self._git.tags], self._repo.release_tag_pattern
        )
        refs = _find_all(
            [r.remote_head for r in self._git.remote().refs],
            self._repo.release_branch_pattern,
        )

        for n, v in refs:
            if v not in releases:
                releases[v] = ReleaseInfo(name=n, version=v, tags=[])

            for tn, tv in tags:
                if tv.startswith(v):
                    releases[v].tags.append(ReleaseTagInfo(name=tn, version=tv))

        for r in releases.values():
            t = sorted(r.tags, key=lambda x: x.version_abs)
            r.tags = t

        return releases


#
# Workspace
#


class Workspace:
    path: Path
    state: ArcState | None
    repos: dict[str, ArcRepository]

    def __init__(self, path: Path) -> None:
        self.path = path
        self.state = None
        self.repos = {}

        if self.is_init():
            self.read_state()
            assert self.state is not None
            self._init()

    @property
    def state_dir(self) -> Path:
        return self.path.joinpath(".arc")

    @property
    def state_file(self) -> Path:
        return self.state_dir.joinpath("state.json")

    def state_exists(self) -> bool:
        state_dir = self.state_dir
        state_file = self.state_file
        return (
            state_dir.exists()
            and state_dir.is_dir()
            and state_file.exists()
            and state_file.is_file()
        )

    def is_init(self) -> bool:
        return self.path.exists() and self.path.is_dir() and self.state_exists()

    def write_state(self) -> None:
        p = self.state_dir
        sf = self.state_file
        assert p.exists() and p.is_dir()
        assert not sf.exists() or sf.is_file()
        if self.state is None:
            warn("No state defined to write to disk!")
            return

        sf.write_text(self.state.json(indent=2))

    def read_state(self) -> None:
        p = self.state_dir
        sf = self.state_file
        assert p.exists() and p.is_dir()
        assert sf.exists() and sf.is_file()
        self.state = ArcState.parse_file(sf)

    def init(self, gh_owner: str, registry: str, config: ArcStateConfig) -> None:

        if self.is_init():
            raise WorkspaceExistsError(self.path)

        # validate that we nothing weird is happening
        if self.state_dir.exists():
            assert self.state_dir.is_dir()
            assert not self.state_file.exists()

        self.path.mkdir(parents=True, exist_ok=True)
        self.state_dir.mkdir(parents=True, exist_ok=True)

        def repo(
            name: str,
            *,
            main_branch: str = "main",
            release_branch_pattern: str = r"s3gw-v(\d+\.\d+)",
            release_tag_pattern: str = r"s3gw-v(\d+\.\d+\.\d+.*)",
        ) -> ArcStateRepo:
            return ArcStateRepo(
                owner=gh_owner,
                repo=name,
                path=self.path.joinpath(f"{name}.git"),
                main_branch=main_branch,
                release_branch_pattern=release_branch_pattern,
                release_tag_pattern=release_tag_pattern,
                registry=f"{registry}/{name}",
            )

        self.state = ArcState(
            repos={
                "s3gw": repo("s3gw", release_tag_pattern=r"v(\d+\.\d+\.\d+.*)"),
                "ceph": repo("ceph", main_branch="s3gw"),
                "ui": repo("s3gw-ui"),
                "charts": repo(
                    "s3gw-charts", release_branch_pattern=r"v(\d+\.\d+\.\d+)"
                ),
            },
            config=config,
            release=None,
        )
        self.write_state()

        self._init()
        self._sync()

    def _init(self) -> None:

        assert self.state is not None

        self._repos = {
            "s3gw": ArcRepository(self.state.config, self.state.repos["s3gw"]),
            "ceph": ArcRepository(self.state.config, self.state.repos["ceph"]),
            "ui": ArcRepository(self.state.config, self.state.repos["ui"]),
            "charts": ArcRepository(self.state.config, self.state.repos["charts"]),
        }

    def _sync(self) -> None:
        assert self.state is not None
        for repo in self._repos.values():
            repo.sync()

    def sync(self) -> None:
        self._sync()
        self.show_status()
        console.print(
            ":boom: [bold dark_orange]Workspace Sync not fully implemented[/bold dark_orange]",
        )

    def show_status(self) -> None:
        table = Table(box=rich.box.SIMPLE, title="Repositories status")
        table.add_column("repository")
        table.add_column("local")
        table.add_column("remote")
        table.add_column("state")
        table.add_column("latest")
        table.add_column("tag")

        for repo in self._repos.values():
            status = repo.check_status()
            releases = repo.get_releases()
            highest = max([x for x in releases.values()], key=lambda x: x.version_abs)
            latest_tag_version = "N/A"
            if len(highest.tags) > 0:
                latest_tag = max(highest.tags, key=lambda x: x.version_abs)
                latest_tag_version = latest_tag.version

            table.add_row(
                repo.full_name,
                status.cur_head.name,
                status.rem_head.name,
                status.state.value,
                highest.version,
                latest_tag_version,
            )

        console.print(table)


#
# Prompts
#

PromptValidator = Callable[[str], bool]


class PromptEntry:
    """
    Prompts for a value, and expects a value that matches a given validator,
    if provided.
    """

    text: str
    validator: None | PromptValidator

    def __init__(self, text: str, validator: None | PromptValidator = None) -> None:
        self.text = text
        self.validator = validator

    def prompt(self, max_len: int = 0) -> str:
        res: str = ""
        while True:
            res = Prompt.ask(f"[bold]{self.text:{max_len}}")
            if self.validator is None:
                break

            if self.validator(res):
                break
            else:
                error("Invalid value entered.")

        return res


class Prompter:
    """Handles a set of prompts."""

    prompts: dict[str, PromptEntry]
    maxlen: int
    results: dict[str, str]

    def __init__(self) -> None:
        self.prompts = {}
        self.maxlen = 0
        self.results = {}

    def add(self, name: str, entry: PromptEntry) -> None:
        self.prompts[name] = entry
        self.maxlen = max(self.maxlen, len(entry.text))

    def prompt(self) -> dict[str, str]:
        for k, v in self.prompts.items():
            self.results[k] = v.prompt(self.maxlen)

        return self.results


def prompt_init_config() -> ArcStateConfig:
    """Run init prompts for state config."""

    def is_not_empty(s: str) -> bool:
        return len(s) > 0

    def is_email(s: str) -> bool:
        return len(s) > 0 and s.find("@") > 0

    def is_ghtoken(s: str) -> bool:
        return len(s) > 3 and s.startswith("ghp_")

    p = Prompter()
    p.add("name", PromptEntry("Name", is_not_empty))
    p.add("email", PromptEntry("email", is_email))
    p.add("key", PromptEntry("GPG Key ID", is_not_empty))
    p.add("token", PromptEntry("GitHub API Token", is_ghtoken))
    res = p.prompt()

    assert "name" in res
    assert "email" in res
    assert "key" in res
    assert "token" in res

    return ArcStateConfig(
        user_name=res["name"],
        user_email=res["email"],
        user_key=res["key"],
        github_token=res["token"],
    )


def prompt_release_start() -> str:
    """Run prompts to start a release."""

    def is_release_version(s: str) -> bool:
        return re.fullmatch(r"^\d+\.\d+\.\d+$", s) is not None

    p = Prompter()
    p.add("version", PromptEntry("Version", is_release_version))
    res = p.prompt()

    assert "version" in res
    return res["version"]


#
# Commands / CLI
#


class ArcContext:
    workspace: Workspace | None

    def __init__(self) -> None:
        self.workspace = None
        cwd = Path.cwd()
        arc = cwd.joinpath(".arc")
        if arc.exists() and arc.is_dir():
            self.workspace = Workspace(cwd)

    @property
    def valid_workspace(self) -> bool:
        return self.workspace is not None and self.workspace.is_init()


@click.group()
@click.pass_context
def arc(ctx: click.Context) -> None:
    """Assisted Release Command is a tool to simplify releasing s3gw."""
    # setup stuff
    ctx.ensure_object(ArcContext)


@arc.command()
@click.pass_context
@click.option(
    "--git-owner",
    type=str,
    default="aquarist-labs",
    show_default=True,
    help="GitHub user/org from where s3gw repositories are consumed.",
)
@click.option(
    "--registry",
    type=str,
    default="quay.io/s3gw",
    show_default=True,
    help="Registry under which s3gw containers are kept.",
)
@click.argument(
    "workspace", type=click.Path(file_okay=False, dir_okay=True, resolve_path=True)
)
def init(ctx: click.Context, workspace: str, git_owner: str, registry: str) -> None:
    """Initiate a workspace where to perform release steps."""

    ws = Workspace(Path(workspace))
    if ws.is_init():
        error(f"Workspace at {workspace} already exists!")
        return

    config: ArcStateConfig = prompt_init_config()
    try:
        ws.init(git_owner, registry, config)
    except ArcError as e:
        print(e)

    info(workspace)
    error(workspace)
    pass


@arc.group()
@click.pass_context
def ws(ctx: click.Context) -> None:
    """Manipulate Workspace."""
    pass


@ws.command("info")
@click.pass_context
def ws_info(ctx: click.Context) -> None:
    """Show Workspace information."""

    arc = ctx.find_object(ArcContext)
    assert arc is not None

    if not arc.valid_workspace:
        error("Current directory is not a valid workspace!")
        return

    assert arc.workspace is not None
    arc.workspace.show_status()
    console.print(arc.workspace.state)


@ws.group("config")
@click.pass_context
def ws_config(ctx: click.Context) -> None:
    """Manipulate Workspace config."""
    pass


@ws_config.command("show")
@click.pass_context
def ws_config_show(ctx: click.Context) -> None:
    """Show Workspace config."""
    pass


@ws.command("sync")
@click.pass_context
def ws_sync(ctx: click.Context) -> None:
    """Synchronize the Workspace's repositories."""

    arc = ctx.find_object(ArcContext)
    assert arc is not None

    if not arc.valid_workspace:
        error("Current directory is not a valid workspace!")
        return

    assert arc.workspace is not None
    arc.workspace.sync()


@arc.group("release")
@click.pass_context
def release(ctx: click.Context) -> None:
    """Perform release related actions."""
    pass


@release.command("start")
@click.pass_context
def release_start(ctx: click.Context) -> None:
    """Start a release."""

    arc = ctx.find_object(ArcContext)
    assert arc is not None

    if not arc.valid_workspace:
        error("Current directory is not a valid workspace!")
        return

    assert arc.workspace is not None
    if arc.workspace.state is not None and arc.workspace.state.release is not None:
        error("On-going release on current workspace.")
        return

    version = prompt_release_start()

    assert arc.workspace.state is not None
    issues = get_project_items(arc.workspace.state.config.github_token, version)
    # console.print(issues)

    open_issues: list[ProjectItem] = []
    open_prs: list[ProjectItem] = []
    for x in issues:
        if x.state.lower() != "open":
            continue
        match x.item_type.lower():
            case "issue":
                open_issues.append(x)
            case "pullrequest":
                open_prs.append(x)
            case _:
                pass

    def show_items(lst: list[ProjectItem], title: str) -> None:
        table = Table(box=rich.box.SIMPLE, title=title)
        table.add_column("repository")
        table.add_column("number")
        table.add_column("title")

        for i in lst:
            table.add_row(i.repository, str(i.number), i.title)

        console.print(table)

    if len(open_issues) > 0:
        show_items(open_issues, title=f"Open Issues for v{version}")

    if len(open_prs) > 0:
        show_items(open_prs, title=f"Open Pull Requests for v{version}")


if __name__ == "__main__":
    arc()
