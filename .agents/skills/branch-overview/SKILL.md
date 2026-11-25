---
name: branch-overview
description: Report where a branch or PR stands — what it does, which areas it touches and how big it is, how far it has diverged from its base (usually dev), what is unfinished, and for PRs the lint/test/check state. Use when asked for a branch overview, branch or PR status, "where is this branch at", or whether a branch is ready to merge.
---

# branch-overview

A read-only status report on one branch. It never builds, runs tests, commits, pushes or comments (CLAUDE.md and AGENTS.md: no builds unless asked). Lint and test state come from CI results on the PR, not from running anything.

Usage: `branch-overview [branch | PR number] [--base <branch>]`

## 1. Resolve the target

- **Head:** the argument (branch or PR number), else the current branch. If it is the checked-out branch, use the local ref so unpushed commits show; otherwise use `origin/<head>`.
- **PR:** find the open PR for the head with whichever GitHub access the session has: GitHub MCP tools (list PRs filtered by head branch, then read the PR) or `gh pr view`. Take owner/repo from `git remote get-url origin`. No PR is normal: skip section 5 and say "No PR".
- **Base:** `--base` if given, else the PR's base, else by branch name:

| Head | Base |
|---|---|
| `feat/*`, `fix/*`, other `type/slug` | `dev` |
| `hotfix/*`, `ci/*` | `master` |
| `dev` | `UAT-testflight` |
| `UAT-testflight` | `master` |

Run `git fetch origin <base> <head>` first (by name, never a bare fetch). Everything below compares `origin/<base>` to the head.

## 2. Gather

```bash
git rev-list --left-right --count origin/<base>...<head>     # behind, ahead
git merge-base origin/<base> <head>                          # then: git log -1 --format='%h %cr' <sha>
git log --format='%h %s' origin/<base>..<head>               # the branch's commits
git diff --numstat origin/<base>...<head>                    # per-file +/- since the merge-base
git merge-tree --write-tree --name-only origin/<base> <head> # exit 1 = conflicts; lists the files
comm -12 <(git diff --name-only $(git merge-base origin/<base> <head>) origin/<base> | sort) \
         <(git diff --name-only origin/<base>...<head> | sort)   # files both sides changed
git status --short; git stash list                           # only when the head is checked out
```

`project.pbxproj` churn is counted but never drives the scale label.

## 3. Report

Use exactly these sections, in this order, as terminal Markdown. Keep each tight; a section with nothing to say is one word ("None"), not padding.

### Summary

One or two sentences: what the branch does and why, drawn from the commit titles and PR description, not from file names.

### Areas touched

Group changed files by area. Show files and +/- per area, largest first, then an overall scale label.

| Area | Paths |
|---|---|
| Study tracking / sessions | `Models/StudySession.swift`, `Models/Subject.swift`, `ViewModels/StudyTrackingViewModel.swift`, `ViewModels/SessionViewerViewModel.swift`, `Views/Sessions/` |
| Focus / timer | `ViewModels/Focus/`, `Views/Focus/`, `Views/Components/PureFocus/`, `Views/Modes/` |
| Study items / fields | `Models/StudyItem.swift`, `Models/Field*.swift`, `Models/ListItem.swift`, `Models/GlobalTags.swift`, `Models/Protocols/` |
| Social / groups | `Views/Social/`, `Views/Groups/`, `Models/SocialFeed.swift`, `Models/RemoteUser.swift`, `ViewModels/SocialFeedViewModel.swift` |
| Profile / settings | `Views/Profile/`, `Views/Settings/`, `ViewModels/Settings/`, `Models/User.swift` |
| App shell / navigation | `studyApp/App/`, `ViewModels/AppSession.swift` |
| Shared UI / extensions | `Shared/`, `Views/Components/` (non-PureFocus), `Extensions/` |
| Networking / backend | any networking or sync layer (none exists yet; match by content such as `URLSession`) |
| Dev tooling / Design Lab | `Views/Dev/`, `ViewModels/Dev/` (call these dev-only) |
| Tests | `studyAppTests/`, `studyAppUITests/`, `studyApp.xctestplan` |
| Docs | `docs/`, `todos/`, `README.md`, other `*.md` |
| Agent guidance | `CLAUDE.md`, `AGENTS.md`, `.claude/` |
| CI / build tooling | `.github/`, `ci_scripts/`, `pipeline.md`, `.swiftlint.yml` |
| Project config / resources | `*.xcodeproj`, `Info.plist`, `*.entitlements`, `studyApp/Resources/` |

A new folder that fits no row gets its own row named after the folder; don't force it into the nearest bucket. A file in two areas goes under the more specific one.

**Scale** from changed lines (excluding `project.pbxproj` and lockfiles): XS under 20, S under 100, M under 400, L under 1000, XL above. Say so when the label misleads, e.g. "L by lines, but a mechanical rename across 40 files".

### Divergence from `<base>`

- Ahead / behind counts, and the merge-base's age.
- How different: files changed, +/-, and the scale label from above.
- Whether it merges cleanly (`merge-tree`); if not, list the conflicted files.
- Files changed on both sides since the merge-base, which are the likely future conflicts even when the merge is clean today.
- Behind by a lot or merge-base older than about two weeks: say it needs updating from `<base>`.

### Outstanding

Report only what is actually found:

- Commits whose subject starts `wip`, `fixup!`, `squash!`, `tmp` or `temp`.
- Added lines (`git diff -U0 origin/<base>...<head>`, ignoring `docs/` and `todos/`) containing `TODO`, `FIXME`, `HACK`, a debug `print(`, or `fatalError("not implemented`.
- Uncommitted or untracked changes, stashes, and commits not pushed (checked-out head only).
- PR only: unticked boxes under "Tested" and any items under "Todo before merge" in the PR description.

### PR state

Omit entirely when there is no PR.

- Draft or ready, mergeable state, review decision, and unresolved review threads.
- **Checks** from the PR's check runs and commit statuses (Xcode Cloud reports as a status): group them as lint, tests/build, PR title and other. For any failed check, fetch its output and quote the first real error line.
- **Lint:** the SwiftLint workflow only runs when `*.swift`, `.swiftlint.yml` or its workflow changed. No lint check on a PR with no Swift changes is expected, not a gap. Errors fail it; warnings are annotations, so count them.
- **Tests:** unit tests run in Xcode Cloud, not GitHub Actions. If no Xcode Cloud or test result is reported, say "no test result reported" and never infer a pass.
- **Title:** check the PR title against `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._-]+\))?!?: .+`, since merge commits take the title.
- **Target:** flag a feature branch whose PR targets `UAT-testflight` or `master`.
- Whether a `/testflight` build was requested.

### Flags

Repo rules the diff may break. Report only those that fire, each in one line:

- **Schema change:** any `@Model` file under `Models/` changed. A reinstall is needed; say whether a migration schema exists or is WIP (CLAUDE.md: follow UAT).
- **Agent docs out of sync:** `CLAUDE.md` or `AGENTS.md` changed without the other.
- **Workflow docs out of sync:** `.github/workflows/` or `ci_scripts/` changed without `.github/workflows/README.md` or `pipeline.md`. `.swiftlint.yml` or `swiftlint.yml` changed: they must stay aligned across `master`, `UAT-testflight` and `dev`.
- **Layer rules:** `import SwiftUI` under `ViewModels/`, or `import SwiftUI`/`import os` under `Models/`.
- **Test gap:** `Models/` or `ViewModels/` changed with nothing under `studyAppTests/`.
- **Commit hygiene:** titles not Conventional Commits; `Co-Authored-By` or other agent trailers present; agent commits not ending in `[AgentName]`; branch name not `type/short-slug`.

### Verdict

One line: **Ready**, **Needs work** or **Blocked**, with the one or two reasons that decide it (conflicts, failing check, WIP commits, missing tests). A branch with no PR can't be Ready, only "No blockers found".
