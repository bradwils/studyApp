---
name: simslim
description: Run, drive and verify studyApp on a memory-slimmed iOS Simulator, using simslim to cut background daemons and the xcodebuildmcp CLI to build, launch, tap, type and capture evidence. Use whenever you need the app running in a simulator, to prove a UI change works, to reproduce a UI bug, or for the G3 gate in gated-loop. Use it in place of the desktop simulator panel.
---

# simslim

Drive studyApp the way a user does, on a simulator that has had unneeded Apple daemons switched off. A slimmed simulator uses less memory and starts faster. Both tools are CLIs, so Claude and Codex follow the same steps.

- `simslim` (`/opt/homebrew/bin/simslim`) slims a simulator and checks it.
- `xcodebuildmcp` (`/opt/homebrew/bin/xcodebuildmcp`) builds, launches and drives the app. Run `xcodebuildmcp <workflow> <tool> --help` for any flag not shown here.

Building is allowed here under the build rule in AGENTS.md. Build once per verification run, not after each edit.

Fixed values:

| Value | Setting |
|---|---|
| Project | `studyApp.xcodeproj` |
| Scheme | `studyApp` |
| Bundle ID | `personal.studyBud` |
| Simulator | The newest-runtime device named `iPhone 17`. Use another device only if the user asks, or if the check is about a size class. |
| Evidence folder | `.verify/<YYYY-MM-DD>-<slug>/` at the repo root. It is git-ignored. |

## Launch

1. **Pick the simulator and resolve its UDID.**
   ```bash
   simslim list --json
   ```
   Take the `udid` of the `iPhone 17` entry with the highest `osVersion`. Use it as `$UDID` for the rest of the run.

2. **Slim it.** The first time only, this reboots the simulator once:
   ```bash
   simslim on "$UDID"
   ```
   The app uses no CloudKit, push, StoreKit, sign-in, HealthKit, Contacts, Calendar or location APIs, so the default profile fits. When a feature needs a disabled category, keep it with `--except <category>`, or keep one daemon with `--keep <label>`. `simslim profiles` lists the categories. Live Activities and widgets need `--except widgets`.

3. **Build, install and launch.**
   ```bash
   xcodebuildmcp simulator build-and-run --project-path studyApp.xcodeproj --scheme studyApp --simulator-id "$UDID" --style minimal
   ```
   For a relaunch with no code change, skip the build:
   ```bash
   xcodebuildmcp simulator launch-app --simulator-id "$UDID" --bundle-id personal.studyBud
   ```

4. **Wait until the app is usable, not just running.** The app opens on the Focus tab:
   ```bash
   xcodebuildmcp ui-automation wait-for-ui --simulator-id "$UDID" --predicate exists --identifier startPauseButton --timeout-ms 15000
   ```

## Doctor

Run this first, and again whenever something looks wrong. All three must pass before you drive.

```bash
simslim status "$UDID"
simslim verify "$UDID"
xcodebuildmcp ui-automation snapshot-ui --simulator-id "$UDID"
```

- `simslim status` must show the simulator as booted and slimmed. If it is stock, run `simslim on "$UDID"` again.
- `simslim verify` exits non-zero when the slim profile has drifted. Re-run `simslim on`.
- `snapshot-ui` must list studyApp's tab bar. An empty or springboard snapshot means the app is not in front, so relaunch it.
- If a feature broke after slimming, run `simslim doctor "$UDID" --requires <feature>`. `simslim doctor --list` shows the feature IDs. If that does not help, run `simslim off "$UDID"`, retest, and report which category was needed.

## Drive

Always snapshot, then act on an element reference from that snapshot, then wait for the result. Never tap by coordinates. Element references go stale after navigation, so take a fresh snapshot after every screen change.

```bash
M=(--simulator-id "$UDID" --style minimal)   # zsh does not split a plain string variable; use an array
xcodebuildmcp ui-automation snapshot-ui $M
xcodebuildmcp ui-automation touch $M --element-ref <ref> --down --up --delay 0.15
xcodebuildmcp ui-automation key-sequence $M --key-codes 16 4 23 11 --delay 0.05
xcodebuildmcp ui-automation swipe $M --within-element-ref <ref> --direction up
xcodebuildmcp ui-automation wait-for-ui $M --predicate exists --identifier <id> --timeout-ms 8000
```

What the first run (iOS 27.0, xcodebuildmcp 2.7.0) showed:

- **Press with `touch`, not `tap`.** `tap` reports success, but the press is dropped on tab bar items and ordinary buttons. `touch --down --up --delay 0.15` registers.
- **Focus a text field before typing.** `touch` the field first. `type-text` into an unfocused field reports success and types nothing. After typing, check the field's value in a fresh snapshot.
- **Fall back to HID key codes for text.** `key-sequence` sends USB HID usage codes and needs no snapshot: `a`=4 to `z`=29, `1`–`9`=30–38, `0`=39, Return=40, Space=44. The field's own autocapitalisation applies.
- **Press the button rather than Return.** Return can be used up accepting the keyboard's predictive suggestion instead of submitting.
- **Run one `ui-automation` call at a time.** A call queued behind a slow one can time out after 30 s and then run later. If a call hangs for more than a minute, run `pkill -f "axe describe-ui --udid $UDID"` and retry. macOS has no `timeout` command, so do not wrap calls in it.

Stable handles in the app:

| Handle | Where |
|---|---|
| Tab labels `Focus`, `Debug`, `Social`, `Groups`, `Sessions`. In a snapshot, a tab's id is its SF Symbol name, and its value is `1` when selected. | `App/MainTabView.swift` |
| `startPauseButton`, `endSessionButton` | `Views/Focus/Components/SessionControls.swift` |
| `editSubjectsButton` | `Views/Settings/SettingsView.swift` |
| `subjectNameField`, `subjectCodeField`, `addSubjectButton`, `subjectRow_<CODE>` | `Views/Settings/SubjectsEditor.swift` |
| `placePickerButton`, labelled with the chosen place or `Add place` | `Views/Components/PlacePicker.swift` |
| `editPlacesButton` | `Views/Settings/SettingsView.swift` |
| `placeNameField`, `addPlaceButton`, `placeRow_<Name>` | `Views/Settings/PlacesEditor.swift` |
| Navigation titles `Settings`, `Social`, `Groups`, `Sessions` | Each tab's root view |

When a flow needs a control with no stable handle, add an `.accessibilityIdentifier` in the same change and add it to this table.

The feature files in `features/` give the route and the proof for each feature.

## Evidence

A proof is the action plus the resulting state, captured from the running app.

```bash
mkdir -p .verify/<run>
xcrun simctl io "$UDID" screenshot --type=jpeg .verify/<run>/<step>.jpg
xcodebuildmcp ui-automation snapshot-ui --simulator-id "$UDID" --output json > .verify/<run>/<step>-snapshot.json
```

`simctl io` writes the screenshot straight to the evidence folder. `xcodebuildmcp simulator screenshot` also works, but it returns a compressed JPEG in a temporary folder that has to be copied over.

- Capture before and after for every step a check depends on.
- Drive the real user path. Do not use debug-only setters to reach a state, unless the feature file says the Debug tab is the route.
- For persistence, prove it survives a restart: stop the app, launch it again, and show the data is still there.
  ```bash
  xcodebuildmcp simulator stop --simulator-id "$UDID" --bundle-id personal.studyBud
  ```
- For memory, `simslim measure "$UDID"` gives the simulator's footprint.

## Cleanup

- Stop the app you launched:
  ```bash
  xcodebuildmcp simulator stop --simulator-id "$UDID" --bundle-id personal.studyBud
  ```
- Leave the simulator booted and slimmed for the next run. Slimming persists until `simslim off`.
- Never erase, delete or `disk-clean` a simulator without the user's approval. Those commands are permanent.
- Keep `.verify/<run>/`. It is the proof. The user deletes old runs.

## Keeping this skill honest

When a drive fails because this file is wrong, fix this file in the same change. The cause may be a renamed identifier, a new tab, or a changed route. Once a release, or when asked to "audit simslim":

1. Drive every feature in `features/` once, one after another.
2. Fix any drift you find.
3. Report each feature as `verified`, `fixed` or `unreachable`, giving the prerequisite for any that are unreachable.

Adapted from create-verification-skill and maintain-verification-skill in [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
