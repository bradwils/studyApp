#!/usr/bin/env python3

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from zoneinfo import ZoneInfo


SYDNEY = ZoneInfo("Australia/Sydney")
MAX_LENGTH = 3500


def text(value, label):
    if not isinstance(value, str) or not value.strip() or "\n" in value or "\r" in value:
        raise ValueError(f"{label} must be a nonempty, single-line string")
    return value.strip()


def load(path):
    with path.open() as source:
        result = json.load(source)
    if not isinstance(result, dict):
        raise ValueError(f"{path}: expected a JSON object")
    return result


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def records(root):
    folder = root / "TestFlight"
    release = load(folder / "release.json")
    cycle = text(release.get("cycle"), "release.cycle")
    text(release.get("baseline"), "release.baseline")
    changes, promotions = [], []
    for path in sorted((folder / "entries").glob("*.json")):
        entry = load(path)
        if text(entry.get("cycle"), f"{path.name}.cycle") != cycle:
            continue
        kind = entry.get("kind")
        if kind == "promotion":
            source = text(entry.get("from"), f"{path.name}.from")
            target = text(entry.get("to"), f"{path.name}.to")
            if source == target:
                raise ValueError(f"{path.name}: promotion source and target must differ")
            promotions.append(f"{source} → {target}")
            continue
        if kind != "change":
            raise ValueError(f"{path.name}: kind must be change or promotion")
        origin = entry.get("origin")
        if not isinstance(origin, list) or not origin:
            raise ValueError(f"{path.name}: origin must list the branch progression")
        entry["origin"] = [text(branch, f"{path.name}.origin") for branch in origin]
        if not re.fullmatch(r"[0-9a-f]{40}", str(entry.get("base_commit", ""))):
            raise ValueError(f"{path.name}: base_commit must be a full Git commit SHA")
        if type(entry.get("user_visible")) is not bool:
            raise ValueError(f"{path.name}: user_visible must be true or false")
        entry["summary"] = text(entry.get("summary"), f"{path.name}.summary")
        checks = entry.get("checks")
        if not isinstance(checks, list) or (entry["user_visible"] and not checks):
            raise ValueError(f"{path.name}: visible changes need at least one check")
        entry["checks"] = [text(check, f"{path.name}.checks") for check in checks]
        changes.append(entry)
    return release, changes, list(dict.fromkeys(promotions))


def metadata(root, version, build, lane, now=None):
    now = now or datetime.now(timezone.utc)
    local = now.astimezone(SYDNEY)
    return {
        "version": text(version, "version"),
        "build": text(build, "build"),
        "lane": text(lane, "lane"),
        "commit": git(root, "rev-parse", "HEAD"),
        "built_at": now.isoformat(),
        "build_time": f"{local.day} {local:%b %Y %H:%M %Z}",
    }


def render(root, build):
    release, changes, promotions = records(root)
    visible = [entry for entry in changes if entry["user_visible"]]
    selected = visible or changes
    lines = [
        f"{build['version']} ({build['build']}) · {build['lane']}",
        f"Built: {build['build_time']}",
        f"Commit: {build['commit'][:12]}",
        "",
        f"Scope: cumulative notes for {release['cycle']}.",
        f"Baseline: {release['baseline']}",
    ]
    if selected:
        lines += ["", "Branch origins"]
        for origin in dict.fromkeys(" → ".join(entry["origin"]) for entry in selected):
            lines.append(f"• {origin}")
    if promotions:
        lines += ["", "Recorded promotions"] + [f"• {path}" for path in promotions]
    lines += ["", "What to test"]
    if not changes:
        lines.append("Testing instructions have not been recorded for this release cycle.")
    elif not visible:
        lines.append("Internal changes only; no app appearance or behavior changes expected.")
    for entry in selected:
        lines.append(f"• {entry['summary']}")
        if visible:
            lines.extend(f"  - {check}" for check in entry["checks"])
    result = "\n".join(lines) + "\n"
    if len(result) > MAX_LENGTH:
        raise ValueError(f"notes exceed the {MAX_LENGTH}-character project budget; consolidate this cycle's entries")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["preview", "stamp", "generate"])
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--version", default="preview")
    parser.add_argument("--build", default="preview")
    parser.add_argument("--lane")
    args = parser.parse_args()
    root = args.root.resolve()
    folder = root / "TestFlight"
    metadata_path = folder / "build-metadata.json"
    if args.command == "generate":
        build = load(metadata_path)
        if build.get("commit") != git(root, "rev-parse", "HEAD"):
            raise ValueError("build metadata belongs to a different commit; run the pre-build hook first")
        result = render(root, build)
        (folder / "WhatToTest.en-US.txt").write_text(result)
        print(result, end="")
        return
    lane = args.lane or os.environ.get("CI_TAG") or os.environ.get("CI_BRANCH")
    lane = lane or git(root, "branch", "--show-current") or "detached"
    if args.command == "stamp" and (args.version == "preview" or args.build == "preview"):
        raise ValueError("stamp requires the stamped --version and --build")
    build = metadata(root, args.version, args.build, lane)
    result = render(root, build)
    if args.command == "stamp":
        metadata_path.write_text(json.dumps(build, indent=2) + "\n")
        print(build["build_time"])
    else:
        print(result, end="")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, KeyError) as error:
        print(f"error: TestFlight notes: {error}", file=sys.stderr)
        sys.exit(1)
