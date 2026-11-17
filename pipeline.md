# Pipeline

How code moves from a feature branch to the App Store, and what you have to do
at each hop.

CI app builds run on **Xcode Cloud**. GitHub Actions handles repository checks,
the `@claude` bot and requests for PR TestFlight builds; it does not build the
app itself. See the [GitHub Actions workflow table](.github/workflows/README.md)
for triggers and requirements.

---

## Branch map

| Branch | Holds | Builds when | Lands in | Xcode |
|---|---|---|---|---|
| Feature branches (`type/*`) | work in progress | on `/testflight` request for an eligible PR | PR workflow distribution | PR workflow settings |
| `dev` | integrated, unverified | every push | TestFlight internal → **Self** | Latest Release |
| `UAT-testflight` | ready to test, may be rough | every push | TestFlight external → **UAT** | pinned (26.6) |
| `master` | shipped | `v*` tag only | TestFlight external → **Stable**, then App Store review | pinned (26.6) |

Direction is normally feature branch → `dev` → `UAT-testflight` → `master`. Nothing
skips a step except a hotfix or CI maintenance (see below). The table describes
automatic lane builds; an eligible PR from any head branch can also request a
separate PR workflow build.

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
git checkout -b feat/my-feature
```

Use `type/short-slug` branch names and Conventional Commits titles, for example
`feat/sub-timer` and `feat(timer): add a countdown`. PR titles follow the same
convention because merge commits take the PR title. Agent-written commit subjects
end with the agent's name in brackets; do not add `Co-Authored-By` trailers.

Feature pushes do not automatically start an app build. To request a TestFlight
build of an eligible PR's head branch, put `/testflight` on its own line in its
description or an eligible comment. See the [workflow table](.github/workflows/README.md)
for triggers, permissions and configuration.

---

## Feature branch → `dev`

Open a PR targeting `dev` (or push straight to `dev` for small changes).

Before you merge:

- Build locally at least once. Automated SwiftLint checks apply to relevant
  changes, but no CI workflow currently compiles and tests PRs. Agents must not
  build or compile unless the user directly asks for a build.
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
- Preview the Git-derived TestFlight notes for the destination lane. See
  [TestFlight notes](#testflight-notes).

On merge, `UAT-testflight` builds and goes to the **UAT** group. Every push
here builds, so merge once, deliberately.

---

## `UAT-testflight` → `master`

Open a PR from `UAT-testflight` targeting `master`, and merge it with **Create
a merge commit**. The `source-branch` check rejects a PR from anything other
than `UAT-testflight`, `hotfix/*` or `ci/*`. The latter two are exceptions for
production fixes and CI maintenance, respectively.

**Merging does not start a release build.** The `master` release workflow starts
only on a version tag. Merging and releasing are separate decisions; an eligible
PR may also request a separate PR workflow build.

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

Xcode Cloud generates `TestFlight/WhatToTest.en-US.txt` from Git history and
build metadata. No release-cycle JSON, manual summaries or promotion entries
are required. Commit titles, including merge commits, appear directly in the
notes, so write them clearly. No GitHub token, App Store Connect key, AI service
or additional package is needed for note generation. The scripts must reach
each building branch before that branch can generate notes.

### Contents and commit range

Each build includes its version, build number, branch/tag, full checkout commit
SHA, UTC timestamp and Sydney display time (AEST/AEDT). It also lists which of
`dev`, `UAT-testflight` and `master` contain that commit at the time metadata is
stamped. This is Git ancestry at build time, not a historical branch-creation
chain. Deleted branch names and the order of past promotions cannot reliably be
reconstructed from Git alone.

Commit titles are listed newest first, with abbreviated SHAs. A target range
means all commits reachable from the build that are not reachable from the
target (`git log TARGET..BUILD`), including merged feature history. Shared
history and target-only commits are excluded. This is a comparison of commit
ancestry, not a file diff or the exact date a branch was originally created.
Rebased or cherry-picked equivalents can appear because their SHAs differ.
If the target already contains the entire build, the notes explicitly report
that there are no unique commits.

The target is selected in this order:

1. `--target BRANCH`, for local commands.
2. The `TESTFLIGHT_TARGET_BRANCH` workflow environment variable.
3. Xcode Cloud's `CI_PULL_REQUEST_TARGET_BRANCH`, when available. Its
   `CI_PULL_REQUEST_TARGET_COMMIT` pins the comparison snapshot when provided.
4. These lane defaults:

| Build location | Comparison |
|---|---|
| `dev` | Commits not yet in `UAT-testflight` |
| `UAT-testflight` | Commits not yet in `master` |
| `ci/*`, `hotfix/*` | Commits not yet in `master` |
| Other feature branches | Commits not yet in `dev` |
| `master` or a tag | Since the nearest earlier reachable `v*` version tag |

For master/tag builds, tags on the build's own commit are excluded from baseline
selection, so rebuilding a release still shows its changes. If there is no
earlier version tag, the notes explicitly use all reachable history.

The `/testflight` GitHub Action requests a **branch build**, rather than a native
Xcode Cloud pull-request build. Apple may therefore omit the PR environment
variables; these builds use the lane defaults above. Set
`TESTFLIGHT_TARGET_BRANCH` on the Xcode Cloud workflow when its comparison target
needs to differ. The script does not query GitHub to discover an open PR.
The comparison label and full target/base SHA are included in the notes.

### Generation and storage

Before each xcodebuild invocation, `ci_pre_xcodebuild.sh` stamps the version,
build number and lane, fetches origin's branches/tags and completes shallow Git
history. Missing targets, unrelated histories or fetch failures stop generation
with an explicit error rather than silently describing incomplete history.
Only the build checkout's Git refs/history are updated; nothing is committed or
pushed back to the repository.

The pre-build hook saves an ignored `TestFlight/build-metadata.json` snapshot,
including the selected commit titles and branch containment. One timestamp is
used for that snapshot and `StudyAppBuildTime` in the app's Info.plist. This
keeps the history range stable between pre-build and post-build even if remote
branches move. The `TestFlight/` folder is created automatically when needed.

The post-build hook writes `TestFlight/WhatToTest.en-US.txt` only when
`CI_APP_STORE_SIGNED_APP_PATH` is a directory, following Apple's documented
[TestFlight notes mechanism](https://developer.apple.com/documentation/xcode/including-notes-for-testers-with-a-beta-release-of-your-app).
Test/analyze actions do not produce the notes file. Generation rejects metadata
from a different checkout commit. Metadata and notes are ignored by Git and are
not app resources. The generated notes also appear in the post-build log and
are shared with everyone who can access the TestFlight build.

Notes retain the project's conservative 3,500-character budget, counting UTF-16
units so emoji are accounted for conservatively. If the history is too long,
older commit lines are omitted and the footer reports how many commits are
shown. An oversized newest title is shortened with an ellipsis. Build identity
and timestamps are preserved; history length does not fail the build.

### Verification without an app build

From the repository root:

```sh
python3 ci_scripts/testflight_notes.py preview --version 0.3 --build 24 --lane UAT-testflight
python3 ci_scripts/testflight_notes.py preview --target dev
python3 -m unittest discover -s ci_scripts -p 'test_testflight_notes.py'
zsh -n ci_scripts/ci_pre_xcodebuild.sh ci_scripts/ci_post_xcodebuild.sh
```

Preview prints to stdout without creating files or accessing the network.
Use `--fetch` to refresh origin refs and complete shallow history explicitly.
Without it, preview uses the available local refs, preferring `origin/BRANCH`
over a local branch. Python 3.9+ with the standard library and Sydney timezone
data is required. Fixture checks use temporary local Git repositories and do
not compile Swift or contact any service.

After an app build is explicitly authorized, inspect its Xcode Cloud post-build
log and TestFlight's “What to Test” field. Confirm the version/build, branch/tag,
full commit, timestamps, comparison range and commit titles match the upload.
This service-side check cannot be proven by local fixtures.
