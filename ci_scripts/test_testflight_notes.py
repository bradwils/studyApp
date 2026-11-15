import importlib.util
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location("notes", Path(__file__).with_name("testflight_notes.py"))
notes = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(notes)


class TestFlightNotesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "TestFlight/entries").mkdir(parents=True)
        self.write("release.json", {"cycle": "0.3", "baseline": "v0.2"})
        self.build = {
            "version": "0.3", "build": "24", "lane": "UAT-testflight",
            "commit": "a" * 40, "build_time": "15 Nov 2026 15:42 AEDT",
        }

    def write(self, name, value):
        (self.root / "TestFlight" / name).write_text(json.dumps(value))

    def change(self, name="feature", visible=True, **values):
        entry = {
            "cycle": "0.3", "kind": "change",
            "origin": ["dev", "feat/timer", "fix/timer-layout"],
            "base_commit": "b" * 40, "user_visible": visible,
            "summary": "Timer controls fit on small screens." if visible else "CI maintenance.",
            "checks": ["Start a timer; verify all controls remain visible."] if visible else [],
        }
        entry.update(values)
        self.write(f"entries/{name}.json", entry)

    def test_nested_origins_survive_branch_deletion(self):
        self.change()
        result = notes.render(self.root, self.build)
        self.assertIn("dev → feat/timer → fix/timer-layout", result)
        self.assertIn("Start a timer; verify all controls remain visible.", result)
        self.assertIn("0.3 (24) · UAT-testflight", result)
        self.assertIn("15 Nov 2026 15:42 AEDT", result)

    def test_internal_changes_and_origins_are_hidden_in_mixed_release(self):
        self.change()
        self.change("ci", visible=False, origin=["master", "ci/private-detail"])
        result = notes.render(self.root, self.build)
        self.assertNotIn("CI maintenance", result)
        self.assertNotIn("ci/private-detail", result)

    def test_internal_only_release_has_honest_summary(self):
        self.change(visible=False)
        result = notes.render(self.root, self.build)
        self.assertIn("no app appearance or behavior changes expected", result)
        self.assertIn("CI maintenance", result)

    def test_previous_cycles_are_excluded(self):
        self.change("old", cycle="0.2", summary="Old feature")
        self.change()
        self.assertNotIn("Old feature", notes.render(self.root, self.build))

    def test_promotions_are_recorded_separately_and_deduplicated(self):
        self.change()
        promotion = {"cycle": "0.3", "kind": "promotion", "from": "dev", "to": "UAT-testflight"}
        self.write("entries/01-promotion.json", promotion)
        self.write("entries/02-promotion.json", promotion)
        result = notes.render(self.root, self.build)
        self.assertEqual(result.count("• dev → UAT-testflight"), 1)
        self.assertIn("Branch origins", result)
        self.assertIn("Recorded promotions", result)
        self.assertEqual(result, notes.render(self.root, self.build))

    def test_separate_features_keep_separate_origins(self):
        self.change()
        self.change("profile", origin=["dev", "feat/profile"], summary="Profile update")
        result = notes.render(self.root, self.build)
        self.assertIn("dev → feat/profile", result)
        self.assertIn("dev → feat/timer → fix/timer-layout", result)
        self.assertNotIn("fix/timer-layout → feat/profile", result)

    def test_missing_instructions_do_not_claim_no_visible_changes(self):
        result = notes.render(self.root, self.build)
        self.assertIn("have not been recorded", result)
        self.assertNotIn("Internal changes only", result)

    def test_invalid_entries_fail_before_upload(self):
        for field, value in [("user_visible", "false"), ("checks", []), ("base_commit", "abc"), ("origin", []), ("summary", "two\nlines")]:
            with self.subTest(field=field):
                self.change(**{field: value})
                with self.assertRaises(ValueError):
                    notes.render(self.root, self.build)

    def test_overlong_notes_are_not_silently_truncated(self):
        self.change(summary="x" * notes.MAX_LENGTH)
        with self.assertRaisesRegex(ValueError, "consolidate"):
            notes.render(self.root, self.build)

    def test_sydney_summer_and_winter_use_correct_timezone(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-qm", "fixture"], check=True)
        for month, expected in [(1, "16 Jan 2026 01:00 AEDT"), (7, "16 Jul 2026 00:00 AEST")]:
            with self.subTest(month=month):
                build = notes.metadata(self.root, "0.3", "24", "v0.3", datetime(2026, month, 15, 14, tzinfo=timezone.utc))
                self.assertEqual(build["build_time"], expected)
                self.assertEqual(build["lane"], "v0.3")

    def test_hooks_with_real_nested_history_and_deleted_branches(self):
        scripts = Path(__file__).parent
        (self.root / "ci_scripts").mkdir()
        for name in ["ci_pre_xcodebuild.sh", "ci_post_xcodebuild.sh", "testflight_notes.py"]:
            shutil.copy(scripts / name, self.root / "ci_scripts" / name)
        (self.root / "ci_scripts/build_number_offset").write_text("4\n")
        (self.root / "studyApp.xcodeproj").mkdir()
        project = self.root / "studyApp.xcodeproj/project.pbxproj"
        project.write_text("CURRENT_PROJECT_VERSION = 1;\nMARKETING_VERSION = 0.2;\n")
        (self.root / "studyApp").mkdir()
        plist = self.root / "studyApp/Info.plist"
        plist.write_bytes(plistlib.dumps({}))
        self.change()
        self.write("entries/promotion.json", {
            "cycle": "0.3", "kind": "promotion", "from": "dev", "to": "UAT-testflight",
        })

        def run_git(*args):
            return subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True, text=True)

        run_git("init", "-q", "-b", "dev")
        run_git("config", "user.name", "Fixture")
        run_git("config", "user.email", "fixture@example.invalid")
        run_git("add", ".")
        run_git("commit", "-qm", "release baseline")
        run_git("switch", "-qc", "feat/timer")
        run_git("commit", "--allow-empty", "-qm", "feature")
        run_git("switch", "-qc", "fix/timer-layout")
        run_git("commit", "--allow-empty", "-qm", "fix")
        run_git("switch", "dev")
        run_git("merge", "--no-ff", "fix/timer-layout", "-m", "integrate feature and fix")
        run_git("switch", "-qc", "UAT-testflight")
        run_git("branch", "-D", "feat/timer", "fix/timer-layout")
        run_git("tag", "v0.3")
        run_git("checkout", "--detach", "v0.3")
        env = dict(os.environ, CI_PRIMARY_REPOSITORY_PATH=str(self.root), CI_BUILD_NUMBER="28", CI_TAG="v0.3", CI_BRANCH="")
        subprocess.run(["zsh", str(self.root / "ci_scripts/ci_pre_xcodebuild.sh")], env=env, check=True, capture_output=True, text=True)
        build = notes.load(self.root / "TestFlight/build-metadata.json")
        self.assertEqual(build["version"], "0.3")
        self.assertEqual(build["build"], "24")
        self.assertEqual(build["lane"], "v0.3")
        self.assertEqual(plistlib.loads(plist.read_bytes())["StudyAppBuildTime"], build["build_time"])
        output = self.root / "TestFlight/WhatToTest.en-US.txt"
        post = self.root / "ci_scripts/ci_post_xcodebuild.sh"
        env["CI_APP_STORE_SIGNED_APP_PATH"] = ""
        subprocess.run(["zsh", str(post)], env=env, check=True)
        self.assertFalse(output.exists())
        signed_app = self.root / "signed.app"
        signed_app.mkdir()
        env["CI_APP_STORE_SIGNED_APP_PATH"] = str(signed_app)
        subprocess.run(["zsh", str(post)], env=env, check=True, capture_output=True, text=True)
        result = output.read_text()
        self.assertIn("0.3 (24) · v0.3", result)
        self.assertIn("dev → feat/timer → fix/timer-layout", result)
        self.assertIn("dev → UAT-testflight", result)
        self.assertIn(build["build_time"], result)
        subprocess.run(["zsh", str(post)], env=env, check=True, capture_output=True, text=True)
        self.assertEqual(result, output.read_text())
        run_git("commit", "--allow-empty", "-qm", "different build commit")
        stale = subprocess.run(["zsh", str(post)], env=env, capture_output=True, text=True)
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("different commit", stale.stderr)


if __name__ == "__main__":
    unittest.main()
