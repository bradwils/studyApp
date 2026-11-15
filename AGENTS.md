# AGENTS.md

## Build behavior

Do not build or compile this Xcode app unless the user directly asks for a build.
Verify app edits by reading the code and mention when a build has not been run.

## TestFlight notes

- Maintain a unique JSON entry under `TestFlight/entries/` for each change; use
  the active cycle from `TestFlight/release.json`. See `pipeline.md` for examples.
- Record the actual origin branch chain and the full commit SHA the final branch
  started from. Capture this when branching; do not reconstruct unknown names.
- For visible changes, write a short summary and checks with actions and expected
  appearance or behavior. Persistence/loading/error behavior counts as visible.
- Mark implementation-only, CI, docs and refactoring entries `user_visible: false`.
  The generator hides their details when visible changes exist in the cycle;
  an internal-only cycle gets a brief explanation instead.
- For promotion PRs, add a promotion entry with the actual source and destination;
  retain the existing change entries without copying them. Do not record a route
  merely because the pipeline normally follows it.
- Preview with `python3 ci_scripts/testflight_notes.py preview` and verify scripts
  with `python3 -m unittest discover -s ci_scripts -p 'test_testflight_notes.py'`.
  These commands do not build the app.
