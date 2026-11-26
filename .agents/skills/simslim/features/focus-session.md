# Focus session

The core loop: pick a subject, start the timer, pause, resume, and end the session, which saves it.

## Sub-features

- Start, pause and resume through one button, `startPauseButton`, labelled `Start`, `Pause` and `Resume`.
- End session, `endSessionButton`, shown only while paused.
- Subject selection on the tracking page, from `ActiveSubjectList` in `Views/Focus/Pages/TrackingPageContent.swift`.

## How to get to it (user POV)

The app opens on the **Focus** tab. Elsewhere, tap the **Focus** tab.

## Driving it with xcodebuildmcp

1. Wait for `startPauseButton` to exist, then snapshot it and check its label is `Start`.
2. If a subject list is shown, tap a subject row.
3. Tap `startPauseButton`. Wait until its label is `Pause`:
   `wait-for-ui --predicate textContains --identifier startPauseButton --text Pause`
4. Wait at least 3 seconds, then tap `startPauseButton`. The label becomes `Resume`, and `endSessionButton` appears.
5. Tap `endSessionButton`.

## Proof

- After step 3, the timer text changes between two snapshots taken a few seconds apart.
- After step 5, the **Sessions** tab lists a new session at the top, with the chosen subject.
- After a stop and relaunch, that session is still listed.

## Gotchas

- With no subjects, the list is empty. Add one first through the [subjects editor](subjects-editor.md).
- The button morphs with a glass animation. Wait with `--predicate settled` before snapshotting for a screenshot.
