---
name: figure-it-out
description: "Design an auditable plan when no narrower skill fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. Scales rigour to the task, runs a hypothesis loop through gates, and logs decisions. Use for /figure-it-out or 'figure it out'."
disable-model-invocation: true
---

# Figure it out

When the task matches no narrower skill, design the workflow before writing code. The deliverable is a phase list that scales rigour to the task, runs each step as an experiment, and leaves a decision log a human can audit later.

## Start

Read the **brad-behaviour** skill and the sections of **principles** that apply. Then add the phases below to the task list.

## Phase A: Frame

Ground yourself in the code first. Do not start the run until you can state:

- **The definition of done,** as a condition a command or a simulator drive can prove true or false. See **prove-it-works**.
- **The scope,** quantified: the rough number of units and files, plus the blockers you found.
- **The rigour level.**
  - One-way doors get more. These are SwiftData schema changes, data deletion, and anything shipped to TestFlight.
  - Reversible, low-stakes steps get less.
  - Rigour means gates and evidence, not trying harder.

Present the framing before a long run. Reversible work then proceeds, but a multi-hour run earns one checkpoint with the user.

## Phase B: Design the workflow

1. Break the work into units that can each land on their own. Put the riskiest unknown first, and scaffolding and verification before features. See **sequence-verifiable-units**.
2. Capture the baseline from the code before the change, so each check reads as "old value versus new value".
3. For one-way-door design decisions, run **architect**. Skip it for mechanical work whose shape is already clear.
4. Write the checkpoint list using **gated-loop**: each unit with its gate and its pass condition. That list is what the human reviews.

Do the work in the main thread. Use a subagent only as **brad-behaviour** allows.

## Phase C: Run the loop

Each unit is an experiment:
1. State the hypothesis.
2. Make the smallest change.
3. Run the unit's gate.
4. Keep the change if the gate passes, and revert it if not.

- Verify by inspecting the artifact, never by a self-report. When something passes too easily, suspect the observation before the system.
- A verdict is VERIFIED, NOT VERIFIED or INCONCLUSIVE. Inconclusive is not a pass. Do not hide a negative.
- Two failures on one gate trigger **attack-the-premise**.

## Phase D: Keep the decision log

Keep a log at `.verify/<YYYY-MM-DD>-<slug>/decisions.tsv`, with one row per decision or checkpoint. The columns are `time`, `unit`, `decision`, `why`, `evidence` and `verdict`. Add a row as each unit lands, not at the end.

For work a reviewer must trust, copy the log into the PR description, or commit it under `docs/` if the user asks.

## Phase E: Verify and hand back

Check the whole against the Phase A definition of done on the real app, using **simslim** for anything a user sees. Turn any repeated correction into a lint, test or script with **self-correction**.

**Reply:**
- the plan you designed;
- the rigour level, and why;
- the decision log path;
- what is verified against the definition of done;
- what is still open.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
