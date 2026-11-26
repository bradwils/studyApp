---
name: why
description: "Use for \"why does X work this way\", \"why did we pick Y\", design rationale, regressions and postmortems. Answers from the git and PR record and returns a cited read on decisions and tradeoffs. Use how for runtime behaviour."
disable-model-invocation: true
---

# Why

Answer from the record, not the code. Read the commits and PR discussions that introduced the target and every later change to it. Use other sources only when that trail is thin.

1. Find where the code came from:
   - `git log --follow -p -- <file>`;
   - `git log -S '<symbol>'`;
   - `git blame -w -C <file>`, for the lines in question.
2. Read each commit's full message. Conventional Commits titles carry the type and scope.
3. Read each PR's description and review threads with `gh pr view <n> --comments`. Merge commits name the PR number.
4. Check `docs/`, `todos/`, `pipeline.md` and AGENTS.md for a recorded decision.

Cite what the authors wrote. Mark your own inferences as inferences. Say what the record does not answer.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
