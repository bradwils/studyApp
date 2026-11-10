# Study and focus refactor — expected behaviour for manual testing

Covers Steps 2–6 of the [architecture plan](2026-11-10-study-focus-architecture.md). Steps 7 (adaptive header) and 8 (recovery, StudyItems) are not implemented.

**Checked in the simulator** marks what was driven and observed on an iPhone 18 Pro simulator (iOS 27.2) during implementation. Everything else is expected behaviour that has not been exercised.

## Session lifecycle

| Do this | Expect | Checked in the simulator |
|---|---|---|
| Open Focus with no session | Timer shows `--:--`, one page, no dots, Start button | Yes |
| Tap Start | Timer counts up from 00:00, dots appear, a second (focus) page exists | Yes |
| Tap Pause | Timer switches to break time counting up from 00:00; Resume and End Session appear; dots stay visible; swiping to the focus page still works | Yes, except swiping while paused |
| Tap Resume | Timer returns to study time and continues from where it stopped — break time is not included | Yes |
| Pause, then End Session | Returns to idle; the session appears in Sessions with one break for the final pause and no "In progress" label | Yes |
| End a session that was never paused | One section, no breaks | No |
| Open the finished session | Sections sum to the active duration; breaks sum to the rest; total = active + breaks | Yes (5 s section, 4 s break, 9 s total) |
| Switch tabs mid-session and return | Timer has kept counting; same session | No |
| Background the app mid-session and return | Timer shows the correct elapsed time | No |

## Subject

| Do this | Expect | Checked in the simulator |
|---|---|---|
| Idle, with subjects | Picker is enabled; first subject auto-selected when none is chosen | No |
| During a session | Picker is replaced by the session's subject name as plain text ("No subject" if none) | Yes (no-subject case) |
| Delete the selected subject while idle | Picker falls back to the first remaining subject | No |
| Delete a session's subject | The finished session keeps its stored subject name | No |

## Focus target

| Do this | Expect | Checked in the simulator |
|---|---|---|
| Focus page, duration 0 h 0 m | Start Focus Session is disabled | Yes |
| Pick a duration and tap Start Focus Session | Picker rolls up; timer counts down from the duration; the white gradient rises with progress; a reset button appears | Yes |
| Let it reach zero | Timer stays at 00:00, background fully white, the study session keeps running | Yes |
| Tap reset | Target is dropped; timer returns to total study time; picker returns; the session is unaffected | Yes |
| Pause during a target | Timer shows break time; on Resume the countdown continues from the value it had — no jump | No |
| Try to start a target while paused | Start Focus Session is disabled | No |

## Pager and lock

| Do this | Expect | Checked in the simulator |
|---|---|---|
| Swipe starting over the timer digits | Page changes; the timer does not move | Yes |
| Swipe partway and release | Background and dots crossfade with the drag and settle on one page | Partly (end states only) |
| Tap Lock State | Label becomes Unlock State, tab bar hides, swiping is disabled | Yes |
| Tap Unlock State nine times (at least 0.15 s apart) | Still locked; button shakes each time | Yes |
| Tenth tap | Unlocks; tab bar returns | Yes |
| End a session | Focus page and dots disappear; screen is on the tracking page; lock is cleared | Yes (lock clearing not exercised) |
| Reduce Motion on | Background and dots switch at the halfway point instead of crossfading; timer digits change without the rolling transition | No |
| Largest Dynamic Type size | Timer stays aligned with its slot on both pages | No |

## History

| Do this | Expect | Checked in the simulator |
|---|---|---|
| Sessions tab with an unfinished session | Row shows "In progress" | Yes |
| Swipe to delete an unfinished row | Not offered | No |
| Remove Sessions | Finished sessions are deleted; unfinished ones remain | No |

## Known limits

- A session left unfinished by a force-quit stays "In progress" and can only be removed from the Debug data view. Recovery is plan Step 8.
- A failed save shows a "Couldn't Save" alert and leaves the change pending in the context; there is no retry flow. This path has not been triggered.
- The "temp / since last break" text and the "Total 00:00:00" header are still placeholders.
- The page dots are white, so they are invisible once a completed focus target turns the background white. This predates the refactor.
