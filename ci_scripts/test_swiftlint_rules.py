#!/usr/bin/env python3
"""Exercise the repository's custom rules with the pinned SwiftLint executable."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "ci_scripts" / "swiftlint_fixtures.json"
VERSION = "0.65.1"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swiftlint", default="swiftlint", help="SwiftLint executable path")
    args = parser.parse_args()
    executable = shutil.which(args.swiftlint)
    if executable is None:
        parser.error(f"SwiftLint {VERSION} is required; executable not found: {args.swiftlint}")
    version = subprocess.run([executable, "version"], capture_output=True, text=True, check=True)
    if version.stdout.strip() != VERSION:
        parser.error(f"Expected SwiftLint {VERSION}, got {version.stdout.strip()!r}")

    fixtures = json.loads(FIXTURES.read_text())
    failures = []
    for fixture in fixtures:
        with tempfile.TemporaryDirectory(prefix="studyapp-swiftlint-") as directory:
            root = Path(directory)
            shutil.copyfile(ROOT / ".swiftlint.yml", root / ".swiftlint.yml")
            source = root / fixture["path"]
            source.parent.mkdir(parents=True)
            source.write_text(fixture["source"])
            result = subprocess.run(
                [executable, "lint", "--config", ".swiftlint.yml",
                 "--reporter", "json", "--quiet", "--no-cache", fixture["path"]],
                cwd=root, capture_output=True, text=True, timeout=30,
            )
            try:
                violations = json.loads(result.stdout)
                actual = sorted(
                    [item["rule_id"], item["line"], item["severity"]] for item in violations
                )
                expected = sorted(fixture["expected"])
                paths_match = all(Path(item["file"]).resolve() == source.resolve() for item in violations)
            except (json.JSONDecodeError, KeyError, TypeError) as error:
                failures.append(f"{fixture['name']}: invalid SwiftLint output: {error}\n{result.stdout}")
                continue
            # A missing SourceKit runtime or invalid regex must fail, even if SwiftLint exits zero.
            if result.returncode not in (0, 2) or result.stderr.strip() or actual != expected or not paths_match:
                failures.append(
                    f"{fixture['name']}: expected {expected}, got {actual} (exit {result.returncode})"
                    f"\n{result.stderr.strip()}"
                )

    if failures:
        for failure in failures:
            print(f"FAIL {failure}")
        raise SystemExit(1)
    print(f"Passed {len(fixtures)} custom-rule fixtures with SwiftLint {VERSION}.")


if __name__ == "__main__":
    main()
