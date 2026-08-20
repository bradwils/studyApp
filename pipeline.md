# Pipeline

How code moves from a feature branch to the App Store, and what you have to do
at each hop.

Builds run on **Xcode Cloud**. There are no GitHub Actions workflows in this
repo — if a build runs, Xcode Cloud ran it.

---

## Branch map

| Branch | Holds | Builds when | Lands in |
|---|---|---|---|
| `feature/*` | work in progress | never | nowhere |
| `dev` | integrated, unverified | on push | TestFlight → **Dev** group |
| `UAT-testflight` | ready to test, may be rough | on push | TestFlight → **Beta** group |
| `master` | shipped | on `v*` tag only | App Store review |

Direction is always `feature/*` → `dev` → `UAT-testflight` → `master`. Nothing
skips a step except a hotfix (see below).

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

Open a PR targeting `dev`.

Before you merge:

- Build locally at least once. Nothing on CI will catch a compile error for you
  yet — there is no test or validation workflow, so a broken merge reaches
  TestFlight before anyone notices.
- If this is the first change of a new release cycle, bump
  `MARKETING_VERSION` in the project to whatever version you're now working
  toward. See [Versions](#versions).

On merge, `dev` builds and lands in the **Dev** TestFlight group. Internal only.

---

## `dev` → `UAT-testflight`

Open a PR from `dev` targeting `UAT-testflight`.

This is the promotion that matters, because the build goes out to people who
aren't you. Before merging:

- Install the current `dev` build from TestFlight and actually open it.
- Check that `MARKETING_VERSION` is the version you intend testers to see.
- Write TestFlight "What to Test" notes — this is the only place a tester
  learns what changed, since the version number won't tell them.

On merge, `UAT-testflight` builds and goes to the **Beta** group. Every push
here builds, so avoid pushing a stack of small commits one at a time — merge
once, deliberately.

---

## `UAT-testflight` → `master`

Open a PR from `UAT-testflight` targeting `master`.

**Merging does not build anything.** `master` only builds on a version tag.
That's deliberate: merging and releasing are separate decisions.

To actually cut the release, after the PR is merged:

```sh
git checkout master
git pull
git tag v1.2.3
git push origin v1.2.3
```

The tag is what starts the build, and the tag *is* the version — the script at
`ci_scripts/ci_pre_xcodebuild.sh` reads `v1.2.3` and stamps
`MARKETING_VERSION = 1.2.3` into the build. Whatever version was sitting in the
project on `master` is ignored.

Tag format is 1–3 dot-separated integers after the `v`. `v1.2.3`, `v1.2` and
`v2` are all fine. `v1.0.0.1` and `v2.0-beta` are rejected and the build fails
immediately rather than at upload.

Tag names are unique — `v1.2.3` can exist only once. That's the point: a
shipped version can't be quietly rebuilt from different code.

---

## Hotfixes

A production bug shouldn't have to travel the whole chain. Branch off `master`,
fix, tag, then merge the fix *back* down so it isn't lost:

```sh
git checkout master && git pull
git checkout -b hotfix-crash-on-launch
# fix, commit, PR into master, merge
git checkout master && git pull
git tag v1.2.4 && git push origin v1.2.4
```

Then open a second PR merging `master` back into `dev`, or the next release
will silently revert the fix.

---

## Versions

Two numbers, two jobs:

| Setting | Shows as | Who sets it |
|---|---|---|
| `MARKETING_VERSION` | `1.2.3` | you, by hand on `dev` — or the tag, on `master` |
| `CURRENT_PROJECT_VERSION` | the `(314)` | CI, automatically, always |

The build number climbs on every build in every lane and never resets. That's
what keeps uploads from colliding — App Store Connect rejects a build number it
has already seen for a given version.

Use ordinary semver for `MARKETING_VERSION`. Patch for fixes, minor for
features, major when it's a big deal. Don't roll over at 9 — `1.0.14` is
perfectly legal, and capping at 9 forces a minor bump you didn't want.

`dev` and `UAT-testflight` builds show whatever `MARKETING_VERSION` is set in
the project, so bump it at the *start* of a cycle, not the end. Otherwise your
beta testers see the version you already shipped.

---

## Gotchas

**`ci_scripts/` must exist on every branch that builds.** Xcode Cloud reads it
from the branch being built, not from `master`. If `dev` doesn't have it, dev
builds silently keep a hardcoded build number and eventually fail to upload.

**Start conditions are OR'd, not AND'd.** Adding both "Branch Changes" and
"Tag Changes" to one Xcode Cloud workflow means it builds on *either* — not
only when both are true. If dev is building more than expected, this is why.

**No force pushes to `master`.**

**Turn on auto-cancel** for the `dev` and `UAT-testflight` workflows so a new
push kills the in-flight build instead of queueing behind it.

---

## Not built yet

Known gaps, in rough priority order:

1. **No tests run anywhere.** `studyApp.xctestplan` is wired with both unit and
   UI targets and the scheme is shared, so a PR-validation workflow — build and
   test, no archive, no distribution — is mostly configuration rather than
   setup. This is the piece that stops a broken merge reaching testers.
2. UI tests will be slow and flaky on every PR. When tests do get added, run
   unit tests on PRs and UI tests on a nightly schedule against
   `UAT-testflight`.
3. TestFlight group names above (**Dev**, **Beta**) need to match what's
   actually configured in App Store Connect.
