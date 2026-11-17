# AGENTS.md

## Build behavior

Do not build or compile this Xcode app unless the user directly asks for a build.
Verify app edits by reading the code and mention when a build has not been run.

## TestFlight notes

- Notes are generated from Git commit titles and build metadata; do not maintain
  release-cycle JSON, manual summaries or promotion entries.
- Use clear commit titles: they appear directly in TestFlight, including merge
  commits. The generator keeps newest commits and truncates older history to fit.
- Native Xcode Cloud PR builds use their actual target branch. Other builds use
  the lane defaults in `pipeline.md`; `TESTFLIGHT_TARGET_BRANCH` overrides them.
- Branch containment describes where the commit exists at build time. Do not
  present it as a reconstructed branch-creation or promotion history.
- Preview with `python3 ci_scripts/testflight_notes.py preview` and verify scripts
  with `python3 -m unittest discover -s ci_scripts -p 'test_testflight_notes.py'`.
  These commands do not build the app. Preview writes no files unless `--fetch`
  is supplied, which updates local Git refs/history only.
