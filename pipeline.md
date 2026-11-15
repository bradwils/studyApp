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
skips a step except a hotfix or CI maintenance (see below).

The **UAT** and **Stable** groups have no testers yet — builds land there and
wait. Add testers in App Store Connect → TestFlight when testing starts.

---

## Branch rules (GitHub rulesets)

| Branch | Direct push | PR required | Merge method | Other |
|---|---|---|---|---|
| `dev` | ✅ | no | any | no force-push, no deletion |
| `UAT-testflight` | ❌ | yes, from any branch | merge commit only | no force-push, no deletion |
| `master` | ❌ | yes, from `UAT-testflight`, `hotfix/*` or `ci/*` | merge commit only | `source-branch` check must pass; no force-push, no deletion |
| `v*` tags | — | — | — | can't be moved or deleted once created |

Approvals required: 0 (you can't approve your own PR). Head branches are
auto-deleted after merge; the long-lived branches are protected from that.

**Why merge commits only:** a promotion PR from `dev` into `UAT-testflight`
must carry `dev`'s actual commits. Squashing creates a new commit with the same
content but different history, so the branches drift apart and the next
promotion conflicts.

**Land an app change once.** Make it on `dev` and promote it. Opening matching PRs
into `dev` and `master` is what caused the earlier drift.

---

## Starting work

Branch app work off `dev`. Hotfixes and CI maintenance branch off `master`:

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
- Review the cumulative TestFlight notes and add a promotion record from `dev`
  to `UAT-testflight`. See [TestFlight notes](#testflight-notes).

On merge, `UAT-testflight` builds and goes to the **UAT** group. Every push
here builds, so merge once, deliberately.

---

## `UAT-testflight` → `master`

Open a PR from `UAT-testflight` targeting `master`, and merge it with **Create
a merge commit**. The `source-branch` check rejects a PR from anything other
than `UAT-testflight`, `hotfix/*` or `ci/*`. The latter two are exceptions for
production fixes and CI maintenance, respectively.

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
with a `hotfix/` name, fix,
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

## CI maintenance

For CI, tooling or documentation changes that need to reach the default branch
without promoting app work, cut a `ci/*` branch from `master` and open a PR into
`master`. Merge with **Create a merge commit**. The `source-branch` check accepts
the prefix; keeping the change limited to maintenance is a review convention,
not a changed-file restriction.

After merging, merge `master` into `UAT-testflight` through a merge-commit PR
and back into `dev`, preserving each target's current changes. This carries the
same commits through all lanes. UAT and dev still build on push; no release tag
is needed for a CI-only change.

The `source-branch` workflow remains required by the master ruleset. Full
retirement is tracked separately in #164 and requires removing that live status
requirement before deleting the workflow.

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

---

## TestFlight notes

Xcode Cloud generates `TestFlight/WhatToTest.en-US.txt` from reviewed JSON
records. No GitHub token, App Store Connect key, AI service or extra workflow
setting is needed. The scripts must reach each building branch before that
branch can generate notes. Notes are shared by everyone who can access a build.

### Release scope

`TestFlight/release.json` defines a `cycle` and a human-readable `baseline`
(commit or release tag). Entries matching that cycle form cumulative notes for
that release, not a delta since a tester's last installed build. The initial
baseline marks this rollout; older changes and branch origins are not backfilled.
The baseline is descriptive, not a Git-log filter: maintain the cycle on entries.

At the start of a new release cycle, change both fields and add entries with the
new cycle. Keep old entries as history; they are excluded automatically. Avoid
renaming a cycle halfway through testing. Consolidate superseded checks within
the current cycle so testers see the final behavior, not obsolete instructions.

### Change entries

Add `TestFlight/entries/<unique-name>.json` with the code change:

```json
{
  "cycle": "testflight-notes-rollout",
  "kind": "change",
  "origin": ["dev", "feat/focus-timer", "fix/timer-layout"],
  "base_commit": "<full 40-character commit SHA>",
  "user_visible": true,
  "summary": "Timer controls now fit on small screens.",
  "checks": [
    "On a small screen, start a focus session; all timer controls should remain visible without overlapping."
  ]
}
```

Capture `base_commit` with `git rev-parse HEAD` immediately before creating the
final branch. `origin` lists the actual parent chain, ending with that branch;
a direct change on `dev` can use `["dev"]`. For a nested branch, carry forward
the parent's recorded origin and append the new name. Update the same entry for
follow-up commits on that branch; add a new entry for independent work.

Branch names are recorded explicitly because Git commit ancestry does not
preserve a dependable branch-creation history. The renderer does not need live
feature branches, a full clone or reflogs. It cannot detect invented origins or
incorrect visibility classifications; review those fields alongside the code.

Describe what testers can see or do, including persistence, loading and error
behavior. Internal-only changes use `user_visible: false`, a short nontechnical
summary and `checks: []`. If any visible entries exist, internal summaries and
origins are omitted. If all entries are internal, notes explain that no app
appearance/behavior changes are expected and include those short summaries.
Missing entries are reported as missing instructions, never as proof that
nothing changed. This system relies on change authors maintaining the records;
it does not infer user impact from filenames or commit types.

### Promotions

Promotion PRs retain existing entries and add their own uniquely named record:

```json
{
  "cycle": "testflight-notes-rollout",
  "kind": "promotion",
  "from": "dev",
  "to": "UAT-testflight"
}
```

Record the actual source/destination when preparing the promotion PR, including
hotfix or CI routes. It becomes part of the build after that PR is merged.
Keep origins separate from promotion steps: a release with several features has
several origins, not one fabricated linear chain. Repeated promotion edges are
shown once. The current build's branch/tag is always displayed independently;
the generator never assumes a tag came from `master` or that UAT was visited.

### Generation and verification

The pre-build hook stamps version/build/lane as before, then validates the active
records and writes ignored `TestFlight/build-metadata.json`. One timestamp is
used for that metadata and `StudyAppBuildTime`; the Sydney timezone switches
between AEST and AEDT automatically. The metadata includes the year and commit.

The post-build hook generates the notes only when
`CI_APP_STORE_SIGNED_APP_PATH` is a directory, following Apple's documented
[TestFlight notes mechanism](https://developer.apple.com/documentation/xcode/including-notes-for-testers-with-a-beta-release-of-your-app).
Test/analyze actions are skipped. Generation rejects stale metadata from a
different commit. Generated files are ignored and are not app resources.
Malformed active records or notes exceeding the project's conservative
3,500-character budget fail validation before compilation; shorten/consolidate
notes rather than silently truncating testing instructions.

From the repository root, without building the app:

```sh
python3 ci_scripts/testflight_notes.py preview --version 0.3 --build 24 --lane UAT-testflight
python3 -m unittest discover -s ci_scripts -p 'test_testflight_notes.py'
zsh -n ci_scripts/ci_pre_xcodebuild.sh ci_scripts/ci_post_xcodebuild.sh
```

Preview prints to stdout without stamping files. Python 3.9+ with the standard
library and Sydney timezone data is required on the Xcode Cloud image. No Python
packages are installed. Fixture checks cover nested/deleted branches, separate
feature origins, promotions, visibility filtering, old cycles, invalid records,
size limits, timestamps and hook integration. They do not compile Swift or
contact any service.

After this change is merged and an app build is explicitly authorized, inspect
its Xcode Cloud post-build log and TestFlight's “What to Test” field. Confirm the
version/build, branch/tag, Sydney timestamp and testing instructions match the
uploaded build. This last service-side check cannot be proven by local fixtures.
