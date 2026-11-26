---
name: gated-loop
description: Split multi-step work into checkpoints that each end in a gate the agent must pass before moving on. The gates are, from cheapest: static checks, build, focused tests, and a Haiku-judged simulator check for substantial UI changes. Use for any feature, refactor or migration with more than one step, or when asked to "gate", "checkpoint" or "self-verify" work.
---

# Gated loop

Work moves forward only through gates. A gate is a check that runs on the real artifact and returns a verdict. The agent does not judge its own work by reading it back.

## 1. Plan the checkpoints first

Before editing, write the checkpoint list into the task list. Each entry has three parts:

- **Unit.** One small change that leaves the app in a working state, such as the model change, the view model change, or the view change.
- **Gate.** The cheapest gate from the table below that would catch this unit's likely failure.
- **Pass condition.** A sentence that a command's output can prove true or false, such as "`StudySessionTests` passes" or "the Sessions tab lists the new session after relaunch".

Order the units so each one builds on a verified one, riskiest unknown first. See **sequence-verifiable-units** in **principles**.

## 2. Gates, cheapest first

Use the cheapest gate that can fail for the reason you care about. Higher gates cost time and usage, so they run only where the table says.

| Gate | Runs | Cost | Command |
|---|---|---|---|
| G0 static | Every checkpoint | Free | See G0 below |
| G1 build | When a unit changes Swift signatures, models or project files, and at the final checkpoint | About a minute; no model tokens beyond the output | `xcodebuildmcp simulator build --project-path studyApp.xcodeproj --scheme studyApp --simulator-name "iPhone 17" --style minimal` |
| G2 tests | When a unit changes logic that has or needs a test | Minutes | `xcodebuildmcp simulator test --project-path studyApp.xcodeproj --scheme studyApp --simulator-name "iPhone 17" --extra-args "-only-testing:studyAppTests/<Suite>" --style minimal` |
| G3 UI | Only for a substantial UI change, at most once per checkpoint | Simulator time, plus one Haiku call | The **simslim** skill, then the Haiku judge below |

G0 is two commands. Both must print no errors:

```bash
git diff --check
swiftlint lint --quiet $(git diff --name-only --diff-filter=AM "$(git merge-base HEAD origin/dev)" -- '*.swift')
```

SwiftLint's custom rules in `.swiftlint.yml` already enforce the layer rules in AGENTS.md.

Build and test gates are allowed by the build rule in AGENTS.md. Run them at gates, never after each edit. Use `--style minimal` and read only the errors, to save context.

**A substantial UI change** is:
- a new screen or sheet;
- a layout change a user would notice on an existing screen;
- a navigation or tab change;
- a new animation or gesture.

Copy edits, colour constants and accessibility labels are not substantial. They stop at G1.

## 3. Verdicts

Every gate ends in exactly one of these verdicts:

- **VERIFIED.** The command ran and its output proves the pass condition.
- **NOT VERIFIED.** The command ran and the output disproves it.
- **INCONCLUSIVE.** The command could not run, or its output does not decide the condition. This is not a pass.

On NOT VERIFIED, fix and rerun the same gate. After **two** failures on one gate:

1. Stop editing.
2. Write down the premise both fixes assumed.
3. Test the premise directly, following **attack-the-premise** in **principles**.
4. If that does not settle it, stop and report the gate, both failures and the premise to the user.

Never weaken a pass condition or skip a gate to get through it. If the gate itself is wrong, fix the gate as its own change and say so.

## 4. The Haiku UI judge (G3 only)

The main agent drives the simulator, because it already holds the context. A Haiku subagent then judges the evidence against a checklist. The judge is cheap and has no stake in the change passing.

1. Before building, write 3 to 6 acceptance checks a screenshot can prove. For example: "The Start button is visible without scrolling on iPhone 17", or "The session row shows the subject code".
2. Run the **simslim** skill: launch, drive the flow, and save before and after screenshots plus the `snapshot-ui` output for each check.
3. Spawn one subagent with `model: "haiku"`. Give it this brief:

   > You are judging a UI change. You did not make it. For each check below, open the listed screenshot and UI snapshot files and answer PASS, FAIL or CANNOT TELL, with one sentence of evidence from the image or snapshot. Do not suggest fixes. Do not edit files.
   > Checks: <the numbered checks>
   > Evidence: <absolute paths to each screenshot and snapshot>

4. Any FAIL makes the verdict NOT VERIFIED. CANNOT TELL makes it INCONCLUSIVE. Recapture the missing evidence once, then report.
5. Paste the judge's table into the checkpoint's result.

Run at most one judge per checkpoint, and only one model.

## 5. Report

At the end, give one line per checkpoint with the unit, the gate, the verdict and the evidence: a command and its last relevant output line, or a screenshot path. List anything left INCONCLUSIVE separately. Do not fold it into "done".

## Optional: enforce gates with hooks

Hooks make the harness run a gate, so the agent cannot skip it. They are not installed. Ask the user before adding them to `.claude/settings.json`.

- **Free:** a command `Stop` hook that runs the G0 commands and exits with code 2 when one fails. Claude Code then keeps working with stderr as the reason. Check `stop_hook_active` in the hook input and exit 0 when it is `true`, so the hook cannot loop forever.
- **Cheap:** a `"type": "prompt"` `Stop` hook with `"model": "haiku"`. It asks whether every checkpoint in the task list has a VERIFIED or reported verdict. It costs one Haiku call per stop.

Adapted from figure-it-out and sequence-verifiable-units in [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
