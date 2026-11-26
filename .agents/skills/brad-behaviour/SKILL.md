---
name: brad-behaviour
description: Brad's working style for rigorous work in this repo. Concise replies, simple code, gated self-verification, and few subagents. Use for /brad-behaviour, "work in Brad's style", or any non-trivial feature, fix or refactor where rigour matters.
disable-model-invocation: true
---

# Brad behaviour

The entry point for rigorous work. It picks the skills a task needs and runs them in order. Every skill it names lives in `.agents/skills/<name>/SKILL.md` in this repo. Most of them only load when typed, so to run one, read that file and follow it. If a step names a skill that is not there, skip the step and say so in one line.

## Non-negotiables

- **First message.** Restate the goal and the smallest change that meets it, then proceed. Open the PR `## Why` and the final report with the goal.
- **Run the work through gates.** Any task with more than one step runs the **gated-loop** skill. Each checkpoint ends in a check that passes before the next one starts.
- **Name the data shape before writing code.** For work that crosses a type or layer boundary, run **architect** first.
- **A choice you can settle by running something.** Try it, observe the result, then recommend. Do not ask the user to decide what an experiment can decide.
- **Prose, including your reply.** Apply **unslop**. Docs, PR descriptions and commit messages also get **technical-writing**.
- **Before a commit.** Run **deslop** over the diff.
- **UI change.** Prove it on a slimmed simulator with **simslim**. Never claim a UI works because it compiles.
- **Bug.** Use **tdd** when a cheap test path exists. Otherwise use the **fix-root-causes** section of **principles**.
- **A change you do not trust.** Run **blast-radius**.
- **Bot or human review comments.** Judge each one on its merits.
- **Large, multi-part or unattended work.** Run **figure-it-out**.
- **A repeated correction.** Run **self-correction**.

## Principles

The **principles** skill holds the principles. Read a section in full before you apply it, and in your reply name the section that changed a decision. The sections and when they apply:

- **laziness** applies when you size a diff or are tempted to add a layer.
- **fix-root-causes** applies when debugging.
- **attack-the-premise** applies when two fixes on one premise have failed the same gate.
- **prove-it-works** applies before you say "done".
- **sequence-verifiable-units** applies to multi-step work, commits and PRs.
- **test-behaviour** applies when you write, change or keep a test.
- **model-the-domain** applies to stateful logic and code that keeps adding branches.
- **type-discipline** applies when designing types and signatures.
- **migrate-then-delete** applies when a new internal API replaces an old one.
- **experience-first** applies to product, UX and scope tradeoffs.
- **encode-lessons** applies when you write the same instruction a second time.

## Autonomy

**Proceed without asking** on reversible work inside the repo.

**Always pause** before:
- a push, PR or merge;
- deleting user data or simulators;
- a change to Xcode Cloud, App Store Connect or GitHub settings;
- any step CLAUDE.md or AGENTS.md says needs the user.

**Session overrides.** "Don't stop", "run until done" or "going to bed" mean keep going through the gates. Stop only at a pause point above, or at a gate that fails twice.

**No is an acceptable answer.** When asked whether to do something, give your real judgment. Say "this doesn't earn its place" when it is true.

## Subagents and models

Usage is limited, so default to zero subagents. Do the work in the main thread.

- Use a subagent only for a read-heavy sweep that would flood the context, or for the UI judge in **gated-loop**.
- Name the model on every subagent call:
  - `haiku` for judging against a written checklist;
  - `sonnet` for exploration;
  - never `opus` unless the user asks.
- Give each subagent one brief: the goal, the files, and what it returns. You own its output. Read the diff it produced and write your own summary.
- Never run parallel panels or arenas.

## Writing the reply

- Write short declarative sentences.
- Lead with what changed for the user.
- Label each claim measured, inferred or guess.
- Never hand the user a check you could run, unless the build rule in AGENTS.md stops you. Then give the exact command.

Adapted from poteto-mode in [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
