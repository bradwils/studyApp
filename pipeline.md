# Pipeline

How code moves from a feature branch to the App Store, and what you have to do
at each hop.

App builds run on **Xcode Cloud**. GitHub Actions only does repo housekeeping:
`claude.yml` (the `@claude` mention bot) and `promotion-source.yml` (guards
what can merge into `master`). If an app build runs, Xcode Cloud ran it.

---

## Branch map

| Branch | Holds | Builds when | Lands in | Xcode |
|---|---|---|---|---|
| `feature/*` | work in progress | never | nowhere | — |
| `dev` | integrated, unverified | every push | TestFlight internal → **Self** | Latest Release |
| `UAT-testflight` | ready to test, may be rough | every push | TestFlight external → **UAT** | pinned (26.6) |
| `master` | shipped | `v*` tag only | TestFlight external → **Stable**, then App Store review | pinned (26.6) |

Direction is always `feature/*` → `dev` → `UAT-testflight` → `master`. Nothing
skips a step except a hotfix (see below).

The **UAT** and **Stable** groups have no testers yet — builds land there and
wait. Add testers in App Store Connect → TestFlight when testing starts.

---

## Branch rules (GitHub rulesets)

| Branch | Direct push | PR required | Merge method | Other |
|---|---|---|---|---|
| `dev` | ✅ | no | any | no force-push, no deletion |
| `UAT-testflight` | ❌ | yes, from any branch | merge commit only | no force-push, no deletion |
| `master` | ❌ | yes, from `UAT-testflight` or `hotfix/*` | merge commit only | `source-branch` check must pass; no force-push, no deletion |
| `v*` tags | — | — | — | can't be moved or deleted once created |

Approvals required: 0 (you can't approve your own PR). Head branches are
auto-deleted after merge; the long-lived branches are protected from that.

**Why merge commits only:** a promotion PR from `dev` into `UAT-testflight`
must carry `dev`'s actual commits. Squashing creates a new commit with the same
content but different history, so the branches drift apart and the next
promotion conflicts.

**Land a change once.** Make it on `dev` and promote it. Opening matching PRs
into `dev` and `master` is what caused the earlier drift.

---

## Starting work

Branch off `dev`, never off `master`:

```sh
git checkout dev
git pull
git checkout -b my-feature
```

Push freely. Feature branches don't build, so nothing is watching and nothing
is spent.

---

## `feature/*` → `dev`

Open a PR targeting `dev` (or push straight to `dev` for small changes).

Before you merge:

- Build locally at least once. There is no test or validation workflow yet, so
  a compile error reaches TestFlight before anyone notices.
- If this is the first change of a new release cycle, bump `MARKETING_VERSION`
  and the build number offset in the same commit. See [Versions](#versions).

On merge, `dev` builds and lands in the **Self** TestFlight group.

---

## `dev` → `UAT-testflight`

Open a PR from `dev` targeting `UAT-testflight`, and merge it with **Create a
merge commit**.

This is the promotion that matters, because the build goes out to people who
aren't you. Before merging:

- Install the current `dev` build from TestFlight and actually open it.
- Check that `MARKETING_VERSION` is the version you intend testers to see.
- Write TestFlight "What to Test" notes — this is the only place a tester
  learns what changed.

On merge, `UAT-testflight` builds and goes to the **UAT** group. Every push
here builds, so merge once, deliberately.

---

## `UAT-testflight` → `master`

Open a PR from `UAT-testflight` targeting `master`, and merge it with **Create
a merge commit**. The `source-branch` check rejects a PR from anything other
than `UAT-testflight` or `hotfix/*`.

**Merging does not build anything.** `master` only builds on a version tag.
That's deliberate: merging and releasing are separate decisions.

To cut the release, publish a GitHub Release:

1. GitHub → Releases → **Draft a new release**
2. **Choose a tag** → type `v1.2.3` → *Create new tag on publish*
3. **Target**: `master`
4. **Generate release notes** (lists the merged PRs), then **Publish release**

Publishing creates the tag, and the tag starts the Xcode Cloud build. The tag
*is* the version — `ci_scripts/ci_pre_xcodebuild.sh` reads `v1.2.3` and stamps
`MARKETING_VERSION = 1.2.3` into the build.

Tag format is 1–3 dot-separated integers after the `v`. `v1.2.3`, `v1.2` and
`v2` are all fine. `v1.0.0.1` and `v2.0-beta` are rejected and the build fails
immediately rather than at upload.

Always target `master`. Xcode Cloud builds a `v*` tag on whatever commit it
points at, so a tag on `dev` would ship unreleased work.

---

## Hotfixes

A production bug shouldn't have to travel the whole chain. Branch off `master`
with a `hotfix/` name (the `source-branch` check only accepts that prefix), fix,
PR into `master`, then release:

```sh
git checkout master && git pull
git checkout -b hotfix/crash-on-launch
# fix, commit, push, PR into master, merge with a merge commit
```

Then publish a GitHub Release for `v1.2.4` targeting `master`, and merge
`master` back into `dev` so the next release doesn't silently revert the fix:

```sh
git checkout dev && git pull
git merge origin/master
git push
```

---

## Versions

Two numbers, two jobs:

| Setting | Shows as | Who sets it |
|---|---|---|
| `MARKETING_VERSION` | `1.2.3` | you, by hand on `dev` — or the tag, on `master` |
| `CURRENT_PROJECT_VERSION` | the `(4)` | CI, automatically, always |

App Store Connect only needs each **(version, build)** pair to be unique, so the
build number can restart for each new version. CI sets it to Xcode Cloud's
counter minus `ci_scripts/build_number_offset`:

- The counter is shared by every workflow and only goes up, so `dev` and
  `UAT-testflight` can never produce the same number.
- When you bump `MARKETING_VERSION`, set the offset **in the same commit** to
  the counter's current value: Xcode Cloud → Settings → Build Number shows the
  *next* number, so use that minus one. The new version's builds then start
  near 1.
- If the offset is too high (the result would be 0 or less) or isn't a whole
  number, the build fails straight away with a message saying so.
- Don't reuse a version that already has uploads. 0.1 already has builds up to
  the 50s and 1.0 has builds 6–8, so the first version under this scheme
  should be 0.2 or 1.1.

Use ordinary semver for `MARKETING_VERSION`. Patch for fixes, minor for
features, major when it's a big deal. Don't roll over at 9 — `1.0.14` is
perfectly legal.

`dev` and `UAT-testflight` builds show whatever `MARKETING_VERSION` is set in
the project, so bump it at the *start* of a cycle, not the end.

The Settings screen footer shows `lane · version (build)`. CI stamps the lane
(branch or tag name) into Info.plist as `StudyAppLane`; local builds show
`local`. Never hardcode branch-specific values in source — it makes every
promotion conflict.

---

## Xcode versions

`dev` builds with **Latest Release**, so a new Xcode shows up there first.
`UAT-testflight` and `master` are pinned to a known-good version. Once `dev` has
built cleanly on a new Xcode, move the pins up in each workflow's Environment
settings.

The Xcode version is separate from the oldest iOS the app supports
(`IPHONEOS_DEPLOYMENT_TARGET`, currently 26.0). Always build with a recent
Xcode; support older iOS by lowering the deployment target and guarding newer
APIs with `if #available(iOS 26, *)`.

---

## Gotchas

**`ci_scripts/` must exist on every branch that builds.** Xcode Cloud reads it
from the branch being built, not from `master`.

**Start conditions are OR'd, not AND'd.** A workflow with both "Branch Changes"
and "Tag Changes" builds on *either*. That's why `master` has only the tag
condition.

**Clean builds.** `master` and `UAT-testflight` build clean for
reproducibility. `dev` reuses caches for speed.

**App Store Connect sessions expire.** If a Save button spins forever in the
workflow editor, the sign-in has lapsed — the real error is only in the browser
console. Reload, sign in, and redo the edit.

---

## Not built yet

Known gaps, in rough priority order:

1. **No tests run anywhere.** The unit test target doesn't compile (it targets
   the removed `UserProfileStore`). Once it does, add an Xcode Cloud workflow
   that starts on pull requests into `dev`, `UAT-testflight` and `master`,
   builds and runs unit tests (no archive, no distribution), and make it a
   required check in the rulesets.
2. UI tests are slow and flaky per PR. Run them on a nightly schedule against
   `UAT-testflight` instead.
3. TestFlight "What to Test" notes are written by hand. A `ci_post_clone.sh`
   could generate `TestFlight/WhatToTest.en-US.txt` from the git log.
