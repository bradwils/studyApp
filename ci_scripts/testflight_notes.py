#!/usr/bin/env python3

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys
from zoneinfo import ZoneInfo


SYDNEY = ZoneInfo("Australia/Sydney")
MAX_LENGTH = 3500


def text(value, label):
    if not isinstance(value, str) or not value.strip() or not value.isprintable():
        raise ValueError(f"{label} must be a nonempty, single-line string")
    return value.strip()


def git(root, *args, optional=False):
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True,
        text=True, encoding="utf-8", errors="replace",
    )
    if result.returncode:
        if optional:
            return None
        raise ValueError(f"git {args[0]} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def fetch_history(root):
    args = ["fetch", "--prune", "--no-recurse-submodules", "--tags"]
    if git(root, "rev-parse", "--is-shallow-repository") == "true":
        args.append("--unshallow")
    git(root, *args, "origin", "+refs/heads/*:refs/remotes/origin/*")


def branch_commit(root, branch):
    if git(root, "check-ref-format", "--branch", branch, optional=True) is None:
        raise ValueError(f"invalid target branch: {branch}")
    for ref in (f"refs/remotes/origin/{branch}", f"refs/heads/{branch}"):
        commit = git(root, "rev-parse", "--verify", f"{ref}^{{commit}}", optional=True)
        if commit:
            return commit
    return None


def comparison(root, commit, lane, target):
    if target:
        target = text(target, "target branch")
        base = branch_commit(root, target)
        if not base:
            raise ValueError(f"target branch {target!r} is unavailable; fetch origin before generating notes")
        # PR builds use the exact target snapshot supplied by Xcode Cloud.
        if target == os.environ.get("CI_PULL_REQUEST_TARGET_BRANCH"):
            base = os.environ.get("CI_PULL_REQUEST_TARGET_COMMIT") or base
        if not git(root, "merge-base", base, commit, optional=True):
            raise ValueError(f"target branch {target!r} has no shared history with the build")
        return f"{target}..build", base
    if os.environ.get("CI_TAG") or lane == "master" or git(
        root, "show-ref", "--verify", f"refs/tags/{lane}", optional=True
    ):
        # Exclude this build's tags while still searching every merged parent.
        current_tags = git(root, "tag", "--points-at", commit).splitlines()
        previous = git(
            root, "describe", "--tags", "--match", "v[0-9]*", "--abbrev=0",
            *(f"--exclude={tag}" for tag in current_tags), commit, optional=True,
        )
        if previous:
            return f"{previous}..build", git(root, "rev-parse", f"refs/tags/{previous}^{{commit}}")
        return "all history (no earlier version tag)", None
    target = {
        "dev": "UAT-testflight", "UAT-testflight": "master",
    }.get(lane, "master" if lane.startswith(("ci/", "hotfix/")) else "dev")
    return comparison(root, commit, lane, target)


def metadata(root, version, build, lane, target=None, now=None):
    if git(root, "rev-parse", "--is-shallow-repository") == "true":
        raise ValueError("Git history is shallow; run with --fetch to load complete history")
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    local = now.astimezone(SYDNEY)
    commit = git(root, "rev-parse", "HEAD")
    scope, base = comparison(root, commit, lane, target)
    history = git(root, "log", "--topo-order", "--format=%H%x00%s", commit, *([f"^{base}"] if base else []))
    commits = []
    for line in history.splitlines():
        sha, subject = line.split("\0", 1)
        commits.append({"commit": sha, "title": " ".join(subject.split())})
    return {
        "version": text(version, "version"),
        "build": text(build, "build"),
        "lane": text(lane, "lane"),
        "pr_source": os.environ.get("CI_PULL_REQUEST_SOURCE_BRANCH"),
        "pr_target": os.environ.get("CI_PULL_REQUEST_TARGET_BRANCH"),
        "commit": commit,
        "built_at": now.isoformat(),
        "build_time": f"{local.day} {local:%b %Y %H:%M %Z}",
        "comparison": scope,
        "base_commit": base,
        "commits": commits,
    }


def length(value):
    # Count UTF-16 units conservatively so emoji cannot exceed a service field limit.
    return len(value.encode("utf-16-le")) // 2


def render(build):
    lines = [
        f"{build['version']} ({build['build']})",
        f"Branch/tag: {build['lane']}",
        f"Commit: {build['commit']}",
        f"Built (UTC): {build['built_at']}",
        f"Built (Sydney): {build['build_time']}",
    ]
    if build.get("pr_source") and build.get("pr_target"):
        lines.append(f"Branch preview: {text(build['pr_source'], 'PR source branch')} → {text(build['pr_target'], 'PR target branch')}")
    lines.append(f"Comparison: {build['comparison']}")
    header = "\n".join(lines) + "\n\nCommits (newest first):\n"
    commits = [f"• {entry['commit'][:12]} {entry['title']}\n" for entry in build["commits"]]
    result = header + ("".join(commits) if commits else "No commits unique to this build relative to the target.\n")
    if length(result) <= MAX_LENGTH:
        return result
    selected = []
    for line in commits:
        footer = f"… Truncated; showing {len(selected) + 1} of {len(commits)} commits, newest first.\n"
        if length(header + "".join(selected) + line + footer) > MAX_LENGTH:
            if not selected:
                budget = MAX_LENGTH - length(header + footer + "…\n")
                clipped = ""
                for character in line.rstrip("\n"):
                    if length(clipped + character) > budget:
                        break
                    clipped += character
                if not clipped:
                    raise ValueError("build details exceed the TestFlight notes budget")
                selected.append(clipped + "…\n")
            break
        selected.append(line)
    footer = f"… Truncated; showing {len(selected)} of {len(commits)} commits, newest first.\n"
    result = header + "".join(selected) + footer
    if length(result) > MAX_LENGTH:
        raise ValueError("build details exceed the TestFlight notes budget")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["preview", "stamp", "generate"])
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--version", default="preview")
    parser.add_argument("--build", default="preview")
    parser.add_argument("--lane")
    parser.add_argument("--target", help="override the comparison target branch")
    parser.add_argument("--fetch", action="store_true", help="fetch origin branches, tags and full history")
    args = parser.parse_args()
    root = args.root.resolve()
    folder = root / "TestFlight"
    metadata_path = folder / "build-metadata.json"
    if args.command == "generate":
        with metadata_path.open(encoding="utf-8") as source:
            build = json.load(source)
        if build.get("commit") != git(root, "rev-parse", "HEAD"):
            raise ValueError("build metadata belongs to a different commit; run the pre-build hook first")
        result = render(build)
        (folder / "WhatToTest.en-US.txt").write_text(result, encoding="utf-8")
        print(result, end="")
        return
    if args.fetch:
        fetch_history(root)
    lane = args.lane or os.environ.get("CI_TAG") or os.environ.get("CI_PULL_REQUEST_SOURCE_BRANCH") or os.environ.get("CI_BRANCH")
    lane = lane or git(root, "branch", "--show-current") or "detached"
    target = args.target or os.environ.get("TESTFLIGHT_TARGET_BRANCH") or os.environ.get("CI_PULL_REQUEST_TARGET_BRANCH")
    if args.command == "stamp" and (args.version == "preview" or args.build == "preview"):
        raise ValueError("stamp requires the stamped --version and --build")
    build = metadata(root, args.version, args.build, lane, target)
    result = render(build)
    if args.command == "stamp":
        folder.mkdir(exist_ok=True)
        metadata_path.write_text(json.dumps(build, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(build["build_time"])
    else:
        print(result, end="")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError) as error:
        print(f"error: TestFlight notes: {error}", file=sys.stderr)
        sys.exit(1)
