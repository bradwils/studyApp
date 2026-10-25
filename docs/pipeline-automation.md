# Pipeline automation

What runs automatically for each kind of change, on each environment branch.
See [pipeline.md](../pipeline.md) for the procedures; this file only shows what
the automation does.

**Sources.** GitHub rulesets, workflows and triggers were read live on
2026-10-24. Xcode Cloud workflow settings were last read from App Store Connect
on 2026-10-09, so re-check them there if you have changed a workflow since.

**What the three headings mean**

| Heading | Meaning |
|---|---|
| Commits | commits pushed straight to the environment branch (or a tag, for `master`) |
| New PRs | a pull request opened or updated with that branch as its base |
| Branch changes | the branch moving: a PR merge, a direct push, a force-push or delete attempt, and what each one triggers |

**Colours.** grey = GitHub automation, blue = Xcode Cloud, green = allowed,
red = rejected or failed, yellow = a gap or advisory-only check.

Not shown yet: the SwiftLint workflow, merged into `dev` by PR #158 on
2026-10-26 (supersedes #152). It adds a `swiftlint` check to the "New PRs"
diagrams for `dev`, `UAT-testflight` and `master`, and runs on pushes to `dev`;
it reaches UAT and `master` with the next promotion. PR #153 (PR template) is
merged and PR #139 (cloud session tooling) is closed, unmerged.

---

## dev

### Commits

```mermaid
flowchart TD
  A1["Commits pushed"] --> A2{"Which branch"}
  A2 -->|"feature or other branch"| A3["Accepted<br/>no rule, no workflow, no build"]
  A2 -->|"dev directly"| A4{"Ruleset: Protect long-lived branches"}
  A4 -->|"force-push"| A5["Rejected<br/>repository rule violation"]
  A4 -->|"normal push"| A6["Accepted<br/>no PR, review or check required"]
  A6 --> A7["Xcode Cloud: dev testflight<br/>Branch Changes on dev, any file<br/>auto-cancels an older running dev build"]
  A7 --> A8["ci_pre_xcodebuild.sh<br/>build no. = counter minus offset<br/>stamps lane = dev"]
  A8 -->|"offset not a number or too high"| A9["Build fails<br/>nothing uploaded"]
  A8 --> A10["Archive iOS, scheme studyApp<br/>Xcode Latest Release, cached build"]
  A10 --> A11["TestFlight Internal Testing<br/>group Self"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class A3,A6 ok
  class A7,A8,A10,A11 xc
  class A5,A9 bad
```

### New PRs

```mermaid
flowchart TD
  B1["PR opened, edited or updated<br/>base = dev, any head branch"] --> B2["GitHub Action: PR title<br/>job conventional-title"]
  B2 --> B3{"Title matches<br/>type(scope): description"}
  B3 -->|"yes"| B4["Check passes"]
  B3 -->|"no"| B5["Check fails<br/>advisory only: dev requires no checks<br/>the PR can still be merged"]
  B1 --> B6["Not triggered<br/>Promotion source, only PRs into master<br/>Xcode Cloud, it has no PR start condition"]
  B1 --> B7["claude.yml runs only if a comment<br/>or review contains @claude"]
  B7 -->|"mentioned"| B8["Claude Code action responds on the PR"]
  B4 --> B9["Merge available<br/>no required checks, no approvals, any merge method"]
  B5 --> B9
  B9 --> B10["Merging is a branch change on dev<br/>see the next diagram"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class B2,B6,B7,B8 gh
  class B4,B9 ok
  class B5 gap
```

### Branch changes

```mermaid
flowchart TD
  C1["dev changes"] --> C2{"How"}
  C2 -->|"PR merged"| C3["Merge accepted, any method<br/>head branch auto-deleted after merge"]
  C2 -->|"direct push"| C4["Fast-forward accepted"]
  C2 -->|"force-push or delete"| C5["Rejected by ruleset<br/>no bypass actors, so admins too"]
  C3 --> C6["dev has a new tip"]
  C4 --> C6
  C6 --> C7["Xcode Cloud: dev testflight starts<br/>cancels any older running dev build"]
  C7 --> C8["Pre-build script, then Archive iOS"]
  C8 --> C9["TestFlight Internal Testing<br/>group Self"]
  C6 --> C10["Nothing propagates to UAT-testflight or master<br/>promotion is a manual PR"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class C3,C4 ok
  class C5 bad
  class C7,C8,C9 xc
  class C10 gh
```

---

## UAT-testflight

### Commits

```mermaid
flowchart TD
  D1["Commits pushed directly to UAT-testflight"] --> D2["Ruleset: UAT-testflight PRs only<br/>changes must arrive through a pull request"]
  D2 --> D3["Push rejected<br/>no bypass actors, so admins too"]
  D3 --> D4["Nothing runs<br/>no GitHub Action, no Xcode Cloud build"]
  D4 --> D5["Commits reach UAT only inside a merged PR<br/>see the next two diagrams"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class D2,D4,D5 gh
  class D3 bad
```

### New PRs

```mermaid
flowchart TD
  E1["PR opened or updated<br/>base = UAT-testflight"] --> E2["Head branch is not restricted<br/>by convention it is dev, nothing enforces it"]
  E1 --> E3["Ruleset requirements<br/>pull request, 0 approvals, merge commit only"]
  E1 --> E4["Not triggered<br/>PR title check, only PRs into dev<br/>Promotion source, only PRs into master<br/>Xcode Cloud, no PR start condition"]
  E1 --> E5["claude.yml runs only on an @claude mention"]
  E3 --> E6["No required status checks<br/>merge available immediately"]
  E6 -->|"Create a merge commit"| E7["Branch change on UAT-testflight<br/>see the next diagram"]
  E6 -->|"Squash or rebase"| E8["Not allowed by the ruleset"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class E2 gap
  class E3,E4,E5 gh
  class E6,E7 ok
  class E8 bad
```

### Branch changes

```mermaid
flowchart TD
  F1["UAT-testflight changes"] --> F2{"How"}
  F2 -->|"PR merged with a merge commit"| F3["UAT-testflight has a new tip<br/>head branch dev is protected, so it is not auto-deleted"]
  F2 -->|"direct push, force-push or delete"| F4["Rejected by rulesets"]
  F3 --> F5["Xcode Cloud: UAT-testflight starts<br/>Branch Changes, any file<br/>cancels any older running UAT build"]
  F5 --> F6["ci_pre_xcodebuild.sh<br/>build no. = counter minus offset<br/>stamps lane = UAT-testflight"]
  F6 --> F7["Archive iOS, scheme studyApp<br/>Xcode 26.6 pinned, clean build<br/>distribution: App Store Connect"]
  F7 --> F8["TestFlight External Testing<br/>group UAT<br/>first build of a version needs Beta App Review"]
  F8 --> F9["Group has 0 testers today<br/>the build is stored and nobody is notified"]
  F3 --> F10["Nothing propagates to master<br/>promotion is a manual PR"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class F3 ok
  class F4 bad
  class F5,F6,F7,F8 xc
  class F9 gap
  class F10 gh
```

---

## master

### Commits

```mermaid
flowchart TD
  G1["Developer pushes to the repo"] --> G2{"What is pushed"}
  G2 -->|"commits to master"| G3["Rejected by ruleset master: PRs only<br/>no bypass actors, so admins too"]
  G3 --> G4["Nothing runs"]
  G2 -->|"a v* tag, on any commit"| G5["Allowed<br/>the tag ruleset blocks moving and deleting, not creating"]
  G5 --> G6["Xcode Cloud: Master Change Internal CD starts<br/>on whatever commit the tag points to"]
  G6 --> G7["Gap: nothing checks the tagged commit is on master<br/>a v* tag on a dev commit would ship dev code to Stable"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class G3 bad
  class G4 gh
  class G5 ok
  class G6 xc
  class G7 gap
```

### New PRs

```mermaid
flowchart TD
  H1["PR opened or updated<br/>base = master"] --> H2["GitHub Action: Promotion source<br/>job source-branch, re-runs on each push to the PR"]
  H2 --> H3{"Head branch"}
  H3 -->|"UAT-testflight or hotfix/*"| H4["Check passes"]
  H3 -->|"anything else"| H5["Check fails<br/>merge blocked: it is a required status check"]
  H1 --> H6["Not triggered<br/>PR title check, only PRs into dev<br/>Xcode Cloud, no PR start condition"]
  H1 --> H7["claude.yml runs only on an @claude mention"]
  H4 --> H8["Merge available<br/>pull request, 0 approvals, merge commit only"]
  H8 --> H9["Branch change on master<br/>see the next diagram"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class H2,H6,H7 gh
  class H4,H8,H9 ok
  class H5 bad
```

### Branch changes

```mermaid
flowchart TD
  J1["master changes"] --> J2{"How"}
  J2 -->|"PR merged from UAT-testflight or hotfix/*"| J3["master has a new tip<br/>UAT-testflight is protected, so it is not auto-deleted<br/>a hotfix head branch is auto-deleted"]
  J2 -->|"direct push, force-push or delete"| J4["Rejected by rulesets"]
  J3 --> J5["Xcode Cloud has no branch start condition on master<br/>NOTHING BUILDS on merge"]
  J5 --> J6["Release is a separate manual step<br/>publish a GitHub Release, new tag v1.2.3 on master"]
  J6 --> J7["Tag exists, the tag ruleset makes it immutable"]
  J7 --> J8["Xcode Cloud: Master Change Internal CD<br/>start condition: tags beginning with v"]
  J8 --> J9["ci_pre_xcodebuild.sh<br/>tag must be 1 to 3 dot-separated integers, else the build fails<br/>MARKETING_VERSION = tag<br/>build no. = counter minus offset, lane = the tag"]
  J9 --> J10["Archive iOS, scheme studyApp<br/>Xcode 26.6 pinned, clean build<br/>distribution: App Store Connect"]
  J10 --> J11["TestFlight External Testing<br/>group Stable, 0 testers today"]
  J11 --> J12["Manual: submit the build for App Review in App Store Connect"]
  classDef gh fill:#eef2f7,stroke:#64748b,color:#111827
  classDef xc fill:#e0edff,stroke:#2563eb,color:#111827
  classDef ok fill:#e3f5e9,stroke:#1e8e3e,color:#111827
  classDef bad fill:#fde8e8,stroke:#c0392b,color:#111827
  classDef gap fill:#fff4d6,stroke:#b7791f,color:#111827
  class J3,J7 ok
  class J4 bad
  class J5,J6,J12 gh
  class J8,J9,J10,J11 xc
```

---

## Gaps these diagrams show

1. **A `v*` tag on any commit builds and distributes to Stable.** Nothing checks
   the tagged commit is on `master`. Tag rules can stop a tag being moved but
   not stop it being created on the wrong commit; a guard in
   `ci_pre_xcodebuild.sh` is the practical fix.
2. **Nothing builds or tests a pull request.** Xcode Cloud has no PR start
   condition in any workflow (as of 2026-10-09), so the tests that now exist
   run only on a developer machine.
3. **UAT accepts a PR from any branch.** Only `master` checks the source.
4. **The UAT and Stable TestFlight groups have no testers**, so those builds
   are stored but nobody receives them.
5. **The PR title check is dev-only and advisory.** It does not run for
   promotion PRs, whose titles become the merge commit messages on UAT and
   `master`.

---

## Verified 2026-10-26

Checked with draft probe PRs (#159 into `dev`, #160 into `master`, both closed,
branch deleted) and read-only API calls. The SwiftLint workflow was exercised
from PR #158's branch, before #158 merged into `dev`.

| Check | Probe | Expected | Observed | Run |
|---|---|---|---|---|
| `conventional-title` | #158, valid title | pass | pass | [run](https://github.com/bradwils/studyApp/actions/runs/40201720897) |
| `swiftlint` | #158, no violations | pass | pass | [run](https://github.com/bradwils/studyApp/actions/runs/40201720773) |
| `swiftlint` | #159, `import SwiftUI` in a ViewModel and a lowercase type name | fail with two errors | fail, annotations `no_swiftui_in_viewmodels` and `type_name` | [run](https://github.com/bradwils/studyApp/actions/runs/40201886555) |
| `conventional-title` | #159, valid title | pass | pass | [run](https://github.com/bradwils/studyApp/actions/runs/40201886556) |
| `conventional-title` | #159, title edited to a non-conventional one | re-runs and fails | re-ran and failed | [run](https://github.com/bradwils/studyApp/actions/runs/40202002841) |
| `source-branch` | #160, head not `UAT-testflight` or `hotfix/*`, base `master` | fail, merge blocked | fail, `mergeStateStatus` BLOCKED | [run](https://github.com/bradwils/studyApp/actions/runs/40202042185) |
| `swiftlint` | #160, base `master` | runs (paths filter covers `master`) | ran and failed on the probe's errors | [run](https://github.com/bradwils/studyApp/actions/runs/40202042172) |
| PR title check | #160, base `master` | not triggered | no new run; the checks listed on #160 were #159's, matched by commit | n/a |

Other findings:

- The four rulesets match the `pipeline.md` table: no bypass actors, no
  force-push or deletion on the three branches, PR with 0 approvals and merge
  commit only on `UAT-testflight` and `master`, `source-branch` required on
  `master`, `v*` tags blocked from update and deletion. The `UAT-testflight`
  ruleset has no source restriction or required checks (gap 3 stands).
- Xcode Cloud does report to GitHub for branch builds: a check run
  (`studyApp | dev testflight | Archive - iOS`) and a commit status appear on
  `dev` and `UAT-testflight` tip commits. Not every commit has one (`ced5043`
  has none). No Xcode Cloud result was found on `master`, which only builds on
  tags, and it is not a required check on any branch.
- `claude.yml` only fires on `issue_comment`, review, review comment and issue
  events whose text contains `@claude`. Other comments still start a run that
  the job-level `if` marks skipped, so skipped `claude` check runs pile up on
  `master`.
