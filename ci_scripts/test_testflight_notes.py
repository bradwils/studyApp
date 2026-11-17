import importlib.util
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPTS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("notes", SCRIPTS / "testflight_notes.py")
notes = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(notes)


class TestFlightNotesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        self.env = {key: value for key, value in os.environ.items() if not key.startswith(("CI_", "TESTFLIGHT_", "GIT_"))}
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.environment = patch.dict(os.environ, self.env, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)
        subprocess.run(["git", "init", "-q", "-b", "master", str(self.root)], check=True, env=self.env)
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.baseline = self.commit("shared baseline")
        self.git("branch", "UAT-testflight")
        self.git("branch", "dev")
        self.git("switch", "-qc", "feat/timer")
        self.first = self.commit("feat(timer): add timer")
        self.latest = self.commit("fix(timer): fit controls")

    def git(self, *args):
        result = subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True, text=True, env=self.env)
        return result.stdout.strip()

    def commit(self, title):
        self.git("commit", "--allow-empty", "-qm", title)
        return self.git("rev-parse", "HEAD")

    def build(self, lane="feat/timer", **values):
        return notes.metadata(self.root, "0.3", "24", lane, **values)

    def command(self, command, *args, **env):
        return subprocess.run(
            [sys.executable, str(SCRIPTS / "testflight_notes.py"), command, "--root", str(self.root), *args],
            capture_output=True, text=True, env=dict(self.env, **env),
        )

    def test_branch_range_excludes_shared_and_target_only_commits(self):
        self.git("switch", "dev")
        self.commit("target-only work")
        self.git("switch", "feat/timer")
        build = self.build()
        self.assertEqual([item["commit"] for item in build["commits"]], [self.latest, self.first])
        self.assertEqual(build["comparison"], "dev..build")
        self.assertEqual(build["contained_in"], [])
        result = notes.render(build)
        self.assertIn("fix(timer): fit controls", result)
        self.assertNotIn("target-only work", result)
        self.assertNotIn("shared baseline", result)

    def test_default_promotion_targets(self):
        for lane, target in [("dev", "UAT-testflight"), ("UAT-testflight", "master"), ("ci/notes", "master"), ("hotfix/crash", "master")]:
            with self.subTest(lane=lane):
                self.assertEqual(self.build(lane)["comparison"], f"{target}..build")

    def test_actual_pr_target_and_snapshot_override_defaults(self):
        self.git("branch", "-f", "dev", self.first)
        env = dict(CI_PULL_REQUEST_SOURCE_BRANCH="ci/notes", CI_PULL_REQUEST_TARGET_BRANCH="dev", CI_PULL_REQUEST_TARGET_COMMIT=self.baseline)
        result = self.command("preview", **env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Branch/tag: ci/notes", result.stdout)
        self.assertIn("Comparison: dev..build", result.stdout)
        self.assertIn("feat(timer): add timer", result.stdout)
        override = self.command("preview", "--target", "UAT-testflight", **env)
        self.assertIn("Comparison: UAT-testflight..build", override.stdout)

    def test_target_override_environment(self):
        result = self.command("preview", TESTFLIGHT_TARGET_BRANCH="master")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Comparison: master..build", result.stdout)

    def test_already_merged_branch_has_no_unique_commits(self):
        self.git("branch", "-f", "dev", self.latest)
        build = self.build()
        self.assertEqual(build["commits"], [])
        self.assertEqual(build["contained_in"], ["dev"])
        self.assertIn("No commits unique", notes.render(build))

    def test_tag_build_with_deleted_feature_branch_and_merge_history(self):
        self.git("tag", "-a", "v0.2", self.baseline, "-m", "previous release")
        self.git("switch", "master")
        self.git("merge", "--no-ff", "feat/timer", "-m", "Merge timer feature")
        merged = self.git("rev-parse", "HEAD")
        self.git("tag", "-a", "v0.3", "-m", "current release")
        self.git("checkout", "--detach", "v0.3")
        self.git("branch", "-D", "feat/timer")
        build = self.build("v0.3")
        self.assertEqual(build["comparison"], "v0.2..build")
        self.assertEqual(build["base_commit"], self.baseline)
        self.assertEqual([item["commit"] for item in build["commits"]], [merged, self.latest, self.first])
        self.assertEqual(build["contained_in"], ["master"])
        self.assertNotIn("shared baseline", notes.render(build))

    def test_first_release_explicitly_uses_all_history(self):
        build = self.build("master")
        self.assertEqual(build["comparison"], "all history (no earlier version tag)")
        self.assertEqual(len(build["commits"]), 3)
        self.assertIsNone(build["base_commit"])

    def test_previous_release_can_be_on_a_merged_parent(self):
        self.git("tag", "v0.2", self.first)
        self.git("switch", "master")
        self.commit("master maintenance")
        self.git("merge", "--no-ff", "feat/timer", "-m", "merge release work")
        self.git("tag", "v0.3")
        build = self.build("v0.3")
        self.assertEqual(build["comparison"], "v0.2..build")
        self.assertEqual(build["base_commit"], self.first)
        self.assertNotIn(self.first, [entry["commit"] for entry in build["commits"]])

    def test_missing_and_unrelated_targets_fail_explicitly(self):
        with self.assertRaisesRegex(ValueError, "unavailable"):
            self.build(target="missing")
        self.git("switch", "--orphan", "unrelated")
        self.commit("unrelated root")
        self.git("switch", "feat/timer")
        with self.assertRaisesRegex(ValueError, "no shared history"):
            self.build(target="unrelated")

    def test_build_details_include_full_commit_and_both_timestamps(self):
        for month, expected in [(1, "16 Jan 2026 01:00 AEDT"), (7, "16 Jul 2026 00:00 AEST")]:
            with self.subTest(month=month):
                build = self.build(now=datetime(2026, month, 15, 14, tzinfo=timezone.utc))
                result = notes.render(build)
                self.assertIn(self.latest, result)
                self.assertIn(expected, result)
                self.assertIn(f"2026-{month:02d}-15T14:00:00+00:00", result)
                self.assertIn("0.3 (24)", result)

    def test_long_history_keeps_newest_and_reports_truncation(self):
        build = self.build()
        build["commits"] = [{"commit": f"{number:040x}", "title": f"change {number}: " + "details " * 20} for number in range(100, 0, -1)]
        result = notes.render(build)
        self.assertLessEqual(notes.length(result), notes.MAX_LENGTH)
        self.assertIn("change 100:", result)
        self.assertNotIn("change 1:", result)
        self.assertIn("of 100 commits", result)
        self.assertIn(self.latest, result)
        self.assertEqual(result, notes.render(build))

    def test_oversized_unicode_title_is_shortened_within_budget(self):
        build = self.build()
        build["commits"] = [{"commit": self.latest, "title": "fix: " + "🧑🏽‍💻" * 2000}]
        result = notes.render(build)
        self.assertLessEqual(notes.length(result), notes.MAX_LENGTH)
        self.assertIn("fix: ", result)
        self.assertIn("Truncated; showing 1 of 1 commits", result)
        result.encode("utf-8")

    def test_preview_does_not_write_files(self):
        before = self.git("status", "--porcelain")
        result = self.command("preview")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(before, self.git("status", "--porcelain"))
        self.assertFalse((self.root / "TestFlight").exists())

    def test_stamp_freezes_history_and_generate_rejects_other_commit(self):
        stamped = self.command("stamp", "--version", "0.3", "--build", "24")
        self.assertEqual(stamped.returncode, 0, stamped.stderr)
        path = self.root / "TestFlight/build-metadata.json"
        build = json.loads(path.read_text())
        self.git("branch", "-f", "dev", self.latest)
        generated = self.command("generate")
        self.assertEqual(generated.returncode, 0, generated.stderr)
        self.assertEqual(generated.stdout, notes.render(build))
        self.assertEqual((self.root / "TestFlight/WhatToTest.en-US.txt").read_text(), generated.stdout)
        self.commit("new build")
        stale = self.command("generate")
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("different commit", stale.stderr)

    def test_shallow_clone_fetches_full_history_branches_and_tags(self):
        self.git("tag", "v0.2", self.baseline)
        clone = Path(self.temp.name) / "shallow"
        subprocess.run(["git", "clone", "--depth=1", "--branch", "feat/timer", self.root.as_uri(), str(clone)], check=True, capture_output=True, env=self.env)
        with self.assertRaisesRegex(ValueError, "shallow"):
            notes.metadata(clone, "0.3", "24", "feat/timer")
        notes.fetch_history(clone)
        build = notes.metadata(clone, "0.3", "24", "feat/timer")
        self.assertEqual(len(build["commits"]), 2)
        self.assertEqual(notes.git(clone, "rev-parse", "refs/tags/v0.2"), self.baseline)

    def test_hooks_generate_notes_without_building_or_pushing(self):
        (self.root / "ci_scripts").mkdir()
        for name in ["ci_pre_xcodebuild.sh", "ci_post_xcodebuild.sh", "testflight_notes.py"]:
            shutil.copy(SCRIPTS / name, self.root / "ci_scripts" / name)
        (self.root / "ci_scripts/build_number_offset").write_text("4\n")
        (self.root / "studyApp.xcodeproj").mkdir()
        project = self.root / "studyApp.xcodeproj/project.pbxproj"
        project.write_text("CURRENT_PROJECT_VERSION = 1;\nMARKETING_VERSION = 0.2;\n")
        (self.root / "studyApp").mkdir()
        plist = self.root / "studyApp/Info.plist"
        plist.write_bytes(plistlib.dumps({}))
        remote = Path(self.temp.name) / "origin.git"
        subprocess.run(["git", "clone", "--bare", str(self.root), str(remote)], check=True, capture_output=True, env=self.env)
        self.git("remote", "add", "origin", str(remote))
        original_remote = notes.git(remote, "show-ref")
        env = dict(self.env, CI_PRIMARY_REPOSITORY_PATH=str(self.root), CI_BUILD_NUMBER="28", CI_PULL_REQUEST_SOURCE_BRANCH="feat/timer", CI_PULL_REQUEST_TARGET_BRANCH="dev")
        pre = subprocess.run(["zsh", str(self.root / "ci_scripts/ci_pre_xcodebuild.sh")], check=True, capture_output=True, text=True, env=env)
        build = json.loads((self.root / "TestFlight/build-metadata.json").read_text())
        self.assertIn("build number  -> 24", pre.stdout)
        self.assertEqual(build["version"], "0.2")
        self.assertEqual(build["build"], "24")
        self.assertEqual(build["lane"], "feat/timer")
        self.assertEqual(plistlib.loads(plist.read_bytes())["StudyAppBuildTime"], build["build_time"])
        post = self.root / "ci_scripts/ci_post_xcodebuild.sh"
        subprocess.run(["zsh", str(post)], check=True, capture_output=True, env=env)
        output = self.root / "TestFlight/WhatToTest.en-US.txt"
        self.assertFalse(output.exists())
        signed = self.root / "signed.app"
        signed.mkdir()
        env["CI_APP_STORE_SIGNED_APP_PATH"] = str(signed)
        subprocess.run(["zsh", str(post)], check=True, capture_output=True, env=env)
        self.assertEqual(output.read_text(), notes.render(build))
        self.assertEqual(notes.git(remote, "show-ref"), original_remote)


if __name__ == "__main__":
    unittest.main()
