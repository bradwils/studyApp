---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement, ownership or layering questions (\"where should this live\", \"is this the right layer\"). Explains subsystem architecture, runtime flow and onboarding mental models. Use why for motivation."
disable-model-invocation: true
---

# How

Explore the codebase and answer "how does X work?" in the main thread.

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

## 1. Explore

Read the code yourself. Start from the entry point the question names, then follow calls through the layers: View, ViewModel, Model, and SwiftData. Read whole functions, not just search hits. Note each claim's `file:line` as you go.

Use one subagent only when the answer needs a sweep across more than about 15 files. Give it `subagent_type: "Explore"` and `model: "sonnet"`, plus the question and the files to start from. Ask it to return claims with `file:line`, not prose.

## 2. Explain

Write for a junior engineer who is new to this area and must work in it confidently afterwards:

- Give a plain definition first: what the thing is, in one or two sentences.
- Walk the runtime flow in order, as a user action triggers it.
- Say who owns each piece of state, and in which layer.
- Name the files to open first.
- For three or more moving parts, use a short Mermaid diagram.

## 3. Correctness

Every claim cites a `file:line` you read. Mark anything you inferred as inferred. Never state a caller, API or behaviour you have not seen. For follow-up questions, read more code before answering. Do not answer from memory of an earlier read if the code may have changed.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
