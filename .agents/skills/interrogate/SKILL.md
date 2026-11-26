---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"challenge this\", \"stress test this code\", \"find blind spots\" or \"tear this apart\". One adversarial pass tries to break a change or design, and only findings proven by a run survive."
disable-model-invocation: true
---

# Interrogate

Try to break a change or a design. A finding survives only when a run proves it. Report the findings, and do not apply fixes.

This runs as one pass in the main thread, with no panel of agents.

## Frame

The scope is what the user names. Otherwise it is the branch diff from its merge base with `origin/dev`, through the working tree. State the intent first, using the **in-your-own-words** skill, from the user's message, the commits and the PR description. Ask the user when the intent is unclear.

## Attack

Switch sides. You are now trying to prove the change is wrong. Work through these in order and stop when you run out of real leads:

1. **The one fact it's safe because of.** Find it, as in **blast-radius**, and try to falsify it.
2. **Edge states:**
   - empty, nil and first-run data;
   - an active session during the change;
   - relaunch, backgrounding and time-zone changes;
   - a deleted `Subject` with history;
   - Dynamic Type at its largest;
   - a small device.
3. **The layer and AGENTS.md rules** the diff could break.
4. **Callers and data on disk** that a search for the symbol does not show.

Prove each finding with a run against the real code, such as a failing Swift Testing case, a `swift` script for pure logic, or a **simslim** drive. Record the exact command, the output it printed, and the output the intent requires. Leave out anything you did not run. That covers style, naming, structure, and risks that need a future change to matter.

Runs follow the gate rules in **gated-loop**: at most one focused test run per finding.

## Fresh eyes (optional)

When the user asks for a second opinion, spawn **one** subagent with `model: "sonnet"`. Give it the scope, the intent, and this brief:

> Break this change. Prove each finding with a command and its output. Report only what you ran. Do not edit tracked files.

Verify each of its findings by rerunning the command yourself. Never use more than one.

## Output

- **Intent:** the restatement.
- **Findings:** for each verified finding, the command, its output, and how it breaks the intent. Say "no verified findings" when none survive.
- **Dropped:** the leads you checked and why each one is fine.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
