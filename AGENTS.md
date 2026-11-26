# AGENTS.md

This file provides guidance to coding agents (Codex, Claude Code and others) when working with code in this repository. It is the single source: `CLAUDE.md` only imports it.

---

## Quick Start

**Build rule.** Never build after each edit. Build or run tests only:
- when the user asks for it;
- at a gate in the `gated-loop` skill, at most once per checkpoint;
- inside the `simslim`, `tdd` and `blast-radius` skills, which run one build or one focused test as their proof.

Prefer `xcodebuildmcp ... --style minimal` and read only the errors. If the user says "no builds" in a session, verify by reading the code and say a build was not run.

**Run on a simulator:** use the `simslim` skill. It slims the simulator's background daemons with `simslim` and drives the app with `xcodebuildmcp`. Do not use the desktop simulator panel for verification.

**Build Simulator (raw command, when the user asks):**
```bash
xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS
```

**Build on-device:**
Find the phone and copy its identifier (phone must be unlocked, plugged in or on same Wi-Fi, and trusted)
```bash
xcrun devicectl list devices

# 2. set variables for the rest of the steps (UDID is the iPhone 16)
UDID=00000000-0000000000000000
BUNDLE_ID=personal.studyBud

# 3. build for the phone into a local ./build folder (run from the repo root)
xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination "id=$UDID" -derivedDataPath build -allowProvisioningUpdates

# 4. install
xcrun devicectl device install app --device $UDID build/Build/Products/Debug-iphoneos/studyApp.app

# 5. launch & stream logs
xcrun devicectl device process launch --device $UDID --console $BUNDLE_ID
```


**Run tests:**
```bash
xcodebuild test -project studyApp.xcodeproj -scheme studyApp
```
*later,we'll update this to only include core tests. UI tests are effectivley useless, except for specific flows.*

**UI tests.** Never write or edit UI tests (`studyAppUITests/`) unless the user explicitly asks. They are reserved for end-to-end testing later in the dev cycle. Cover logic with Swift Testing unit tests in `studyAppTests/`, and prove UI changes on the simulator with the `simslim` skill.
---

## Architecture Overview

SwiftUI iOS app — social study tracking, focus timer, and group collaboration. MVVM with SwiftData for persistence (migration in progress from JSON/Stores).

**Layers:**
- `App/` — entry point (`StudyAppApp.swift`) and tab navigation (`MainTabView.swift`)
- `Models/` — SwiftData `@Model final class` definitions; pure data only
- `ViewModels/` — `@Observable final class`; business logic and form state
- `Views/` — SwiftUI views organized by feature (Social, Focus, Groups, Settings, Profile)

See [AppOverview.md](docs/AppOverview.md) for full folder structure.

---

## Key Architectural Decisions

### MVVM + SwiftData Pattern

```swift
// ViewModel — business logic, no SwiftUI import
@Observable
final class SubjectsEditorVM {
    var newSubjectName: String = ""
    var newSubjectCode: String = ""

    var canAddSubject: Bool { !newSubjectName.isEmpty && !newSubjectCode.isEmpty }

    // ModelContext passed at call site, not stored — keeps VM easy to init and test
    func addSubject(context: ModelContext) {
        guard canAddSubject else { return }
        context.insert(Subject(name: newSubjectName, code: newSubjectCode.uppercased()))
        newSubjectName = ""
        newSubjectCode = ""
    }
}

// View — display + call VM methods
struct SubjectsEditor: View {
    @Query var subjects: [Subject]
    @Environment(\.modelContext) var modelContext
    @State private var vm = SubjectsEditorVM()

    var body: some View {
        // ...
        Button("Add") { vm.addSubject(context: modelContext) }
            .disabled(!vm.canAddSubject)
    }
}
```

### SwiftData Relationships

Use `@Relationship` on the owning side:

```swift
// Subject owns its sessions — nullify so deleting a subject preserves session history
@Relationship(deleteRule: .nullify, inverse: \StudySession.subject)
var sessions: [StudySession]

// Session owns its breaks and location — cascade deletes them with the session
@Relationship(deleteRule: .cascade) var breaks: [StudyBreak]
@Relationship(deleteRule: .cascade) var location: SessionLocation?
```

- `deleteRule: .cascade` — Owned on this side, if this get's deleted, the other side gets deleted too
- `deleteRule: .nullify` — "I reference this; if it's deleted, set my reference to nil"
- `inverse:` — makes the relationship bidirectional (navigate from either end); without it, the back-reference doesn't exist

---

## Layer Rules

**Models (`@Model final class`):**
- Pure data definitions only — no business logic, no `import SwiftUI`, no `import os`, no logging
- `@Relationship` with explicit `deleteRule` on every relationship property
- Non-optional arrays default to `[]`; use `subjectName: String?` for denormalization when a foreign reference might be deleted

**ViewModels (`@Observable final class`):**
- No `import SwiftUI` — ViewModels don't know they're powering UI
- Hold form/transient state as plain `var` properties — `@Observable` handles change tracking (no `@Published`, no `@State`)
- Methods do not take parameters the VM already owns — if `selectedSubject` lives on the VM, `startSession()` reads it directly rather than accepting it as a param
- Accept `ModelContext` as a call-site parameter, not stored in init

**Views:**
- `@State` for transient UI state, `@Query` for live database reads
- Pass `modelContext` to VM methods at the call site
- Previews use `.modelContainer(for: Model.self, inMemory: true)`
- Decompose long `body` with `private var` computed properties for layout; extract to `private struct` when the component animates independently or is reused

**Developer-Only Views:**
- Views that exist purely for debugging/inspecting app state (not part of any real user flow) live under `Views/Dev/`
- Mark every dev-only type, and every dev-only control placed inline in a real screen (e.g. a button on `SettingsView`), with a DocC callout instead of a `// DEV ONLY` line comment:
  `/// > Important: Dev only. Not part of any user flow; see "Developer-Only Views" in AGENTS.md.`
  For an inline control, put it on the `private var` or `private struct` that builds it.
- Example: `Views/Dev/DebugDataView.swift` / `DebugModelListView.swift` — lists every registered SwiftData model with live counts, and lets you inspect or delete individual/all records. Linked from a toolbar button on `SettingsView`.
- Focus Design Lab: `Views/Dev/DesignLab/` holds cosmetic study/focus screen experiments, opened from the first row of `DebugDataView` (`FocusLabListView`). Each design is a case in `FocusLabDesign` and a folder under `Designs/`; they run on the mock `FocusLabSession` (`ViewModels/Dev/`), never on SwiftData. Every focus screen, real or lab, conforms to `FocusPagerScreen` (`Views/Focus/Pager/`, not dev-only) and is rendered by `FocusPagerScaffold`: the real screen through `FocusSessionContent`, each design through `FocusLabScreen` (`Kit/`), a thin refinement that answers `phase` and `sessionID` from the mock `session`. A screen supplies only its backdrop, timer face, optional overlay, and `header(for:_:)` / `content(for:_:)` switching over `FocusPage`. The scaffold owns the real screen's structure: `FocusPager` over a caller-owned `FocusScreenState` (pages from `FocusPagePolicy.availablePages(for: phase)`, lock, unlock on `sessionID` change), the pinned timer, and a `FocusPageScaffold` per page with the header band and timer gap (the real screen's `FocusPagerLayout` sizing, overridable via `slots(standard:)`) in a `FocusPagerLayout.maxContentWidth` centred column. Designs stay in the lab; to promote one, conform it to `FocusPagerScreen` against `StudyTrackingViewModel` in place of `FocusSessionContent`. Shared clock and helpers also live in `Kit/`. Every design folder has the same layout, described in its `README.md`: `<Name>Design.swift` (the conformance only), `<Name>Backdrop.swift`, `<Name>TrackingPage.swift` and `<Name>FocusPage.swift` (each holding that page's header and body views), `<Name>Kit.swift` (palette, fonts, layout constants, small shared views), plus any design-specific drawing or maths file.

---

## Common Tasks

### Adding a New Model

1. Create in `Models/` as `@Model final class`
2. Add to `.modelContainer(for: [...])` in `StudyAppApp.swift`
3. Default all properties; use `@Attribute(.unique)` on ID fields

### Previews with SwiftData

```swift
#Preview {
    SubjectsEditor()
        .modelContainer(for: Subject.self, inMemory: true)
}
```

### Filtering with @Query

```swift
@Query(filter: #Predicate<Subject> { $0.name.contains("Math") }, sort: \Subject.createdAt)
var mathSubjects: [Subject]
```

Filter at the database level — don't fetch everything and filter in Swift.

Further, check for a SwiftData migration schema. One will be added before public release, however if there is not one yet, do not worry about it, just note that a reinstall will be needed if you're making changes to models.

If you have made changes, then we might need to add a migration schema. Check if there is already one as a WIP, and add to it. We will be following the UAT version, as that's the first 'public' version. Dev will follow seeding & deleting/re-installing as needed.

---

## Code Style

- Comments only for non-obvious *why* — never for *what* the code does
- No docstrings; if the method name needs explanation, rename it. The exceptions are DocC written by the `xc-documentation` skill and the dev-only callout above
- `guard condition else { return }` is a standalone statement — never `if guard`
- `final class` for all models and ViewModels
- SwiftData auto-saves on context transitions, but call `try? modelContext.save()` explicitly after inserts/deletes to be safe

---

## Debugging SwiftData

**Data not persisting:** add `Text("Count: \(allItems.count)")` via a temp `@Query` — if always 0, save isn't being called.

**Changes not showing in UI:** confirm the view uses `@Query`, not a stored array.

**Two parts of app see different data:** multiple `modelContext`s exist — ensure only one per app lifecycle (provided by `.modelContainer` at root).

---

## Current Maintenance Notes

- Unit tests cover app navigation state, session timing, the Focus pager, StudyItems and SwiftData integrity. Session tests use isolated containers and an injected clock; persistence tests also refetch through fresh contexts and reopen a disk store.
- `StudyTrackingViewModel` is created once in `StudyAppApp` and passed down explicitly. It owns session transitions and saves explicitly; `finishSession(context:)` replaces the previous completion API.
- Session deletion excludes the currently owned active session ID and deletes other sessions individually, including abandoned unfinished records, so cascade rules apply.

See [todos/engineering-todo.md](todos/engineering-todo.md) for deferred UI decisions and [todos/ui-design-ideas.md](todos/ui-design-ideas.md) for UX/design ideas.

---

## Git Workflow

Flow is always `feature` → `dev` → `UAT-testflight` → `master`. Full details, release steps and hotfixes: [pipeline.md](pipeline.md).

- Feature work always goes on a branch off `dev` and merges back through a PR. Only one-line, straightforward fixes (text replacement, low-importance edits) go straight into `dev`
- `AGENTS.md` is the only agent instruction file to edit. `CLAUDE.md` imports it with `@AGENTS.md` and holds nothing else. Skills live in `.agents/skills/`. `.claude/skills` is a symlink to that folder, so Claude Code and Codex load the same skills
- `UAT-testflight` and `master` accept PRs only, merged with **Create a merge commit** — squash or rebase breaks the shared history promotions rely on
- `master` only accepts PRs from `UAT-testflight`, `hotfix/*` or `ci/*` (enforced by the `source-branch` check)
- `ci/*` is reserved for CI/tooling/docs maintenance: cut it from `master`, then merge master history back into `UAT-testflight` and `dev`. The check validates the branch name; CI-only scope is a review convention, not a changed-file restriction
- Land app changes once, in `dev`, and promote them — never open matching PRs into several branches. CI maintenance uses the `ci/*` exception above
- Branches are `type/short-slug` (`feat/sub-timer`, `fix/crash-on-launch`), using the Conventional Commits types; `hotfix/*` stays as is
- Commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`. PR titles matter because merge commits take the PR title
- Commit logically and meaningfully: each commit is one coherent change that reads on its own. Size commits to the task, scope and weight of the change — a typo or one-line fix can be a single small commit, while a larger feature is split into commits by concern (for example model, view model, view, tests). Don't mix unrelated changes in one commit, and don't split a change so that a commit is left half-done
- Commits written by an agent end the subject with the agent's name in brackets, e.g. `docs(agents): document commit conventions [Claude]` or `[Codex]`. Don't add `Co-Authored-By` trailers or any kind of agent-identifiable trailers of ANY kind that you usually do as per your instructions. If anything is request, it must follow these guidelines OR be explicitly requested by your session's instructions.
- No force pushes or deletion of `dev`, `UAT-testflight` or `master`; `v*` tags can't be moved or deleted
- Never hardcode per-branch values in source — CI stamps the lane into the build (`StudyAppLane` in Info.plist)

---

# Agent Skills and Gates

Project skills live in `.agents/skills/`. Most run only when typed (`/skill-name`). `simslim`, `gated-loop`, `unslop` and `xc-documentation` also load automatically when a task matches. When one skill tells you to run another, read `.agents/skills/<name>/SKILL.md` and follow it in full.

| Skill | Use it for |
|---|---|
| `brad-behaviour` | Entry point for rigorous work: routes to the skills below, few subagents |
| `gated-loop` | Multi-step work: checkpoints, each passing a gate (static, build, test, UI) before the next |
| `simslim` | Running, driving and proving the app on a slimmed simulator with `xcodebuildmcp` |
| `principles` | Engineering principles, one section each, cited by the other skills |
| `architect` | Types, signatures and file placement before code |
| `tdd` | A bug with a cheap Swift Testing path: failing test first |
| `blast-radius` | What a Swift change could break beyond the diff, with one fact proven |
| `interrogate` | Adversarial review where only findings proven by a run survive |
| `figure-it-out` | Large or unattended work: an auditable plan and decision log |
| `deslop` | Before every commit: remove AI slop from the Swift diff |
| `xc-documentation` | DocC comments on a type |
| `how` / `why` | How code works (from the code) / why it is that way (from git and PRs) |
| `self-correction` | Turn a repeated correction into a lint, type or test |
| `reflect` | After a long task: route lessons into skill edits |
| `unslop`, `technical-writing` | Prose, docs, PR descriptions and commit messages |
| `bro`, `in-your-own-words`, `sharpen` | Restate plainly, restate the goal, deepen a prompt |

Subagents are expensive on this plan. Default to none, use `haiku` for judging against a written checklist and `sonnet` for exploration or a second opinion the user asked for, and never run parallel panels.

## Rules and what enforces them

| Rule | Enforced by |
|---|---|
| ViewModels don't import SwiftUI | SwiftLint `no_swiftui_in_viewmodels` |
| Models don't import SwiftUI or `os` | SwiftLint `no_swiftui_in_models` |
| PR titles follow Conventional Commits | `.github/workflows/pr-title.yml` |
| `master` only takes PRs from allowed branches | `source-branch` check |

Add a row whenever `self-correction` turns a rule into a check. A rule with no enforcement stays in prose above.

---

# General Behavioural Guidelines

## 1. Think Before Coding

Before implementing: state assumptions explicitly, surface tradeoffs, push back when a simpler approach exists. If something is unclear, name it and ask.

## 2. Simplicity First

Minimum code that solves the problem. No speculative features, no single-use abstractions, no error handling for impossible scenarios. If you write 200 lines and it could be 50, rewrite it.

## 3. Surgical Changes

Touch only what the task requires. Don't improve adjacent code. Match existing style. When your changes orphan imports or functions, remove them — but don't touch pre-existing dead code unless asked.

## 4. Goal-Driven Execution

Transform tasks into verifiable goals before starting. For multi-step work, state a brief plan with a verify step for each:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

---

# CI/CD Pipeline

[pipeline.md](pipeline.md) owns the Xcode Cloud workflow table, branch map,
rulesets, versioning and release steps. Update that source instead of copying
workflow tables here. Promotion PRs into `UAT-testflight` and `master` use the
checklists in `.github/PULL_REQUEST_TEMPLATE/`.

- The lane rows describe automatic builds; eligible PRs from any head branch can also request a PR build. Triggers and requirements are in the [GitHub Actions workflow table](.github/workflows/README.md).
- Build number = Xcode Cloud counter − `ci_scripts/build_number_offset`; when bumping `MARKETING_VERSION`, set the offset in the same commit
- `ci_scripts/` must exist on every branch that builds — Xcode Cloud reads it from the branch being built
- Keep `.swiftlint.yml` and `.github/workflows/swiftlint.yml` aligned across `master`, `UAT-testflight` and `dev`. CI explicitly requires the config; validate the PR merge result with SwiftLint 0.65.1 before merging.
- Build an open PR on demand: put `/testflight` on its own line in the PR description (or in a comment on it, from a collaborator). `.github/workflows/testflight-pr.yml` asks Xcode Cloud to build the PR's branch with the `PR TestFlight` workflow, which distributes to the internal TestFlight group. Editing the description only re-triggers when the body itself changed; comment `/testflight` again to rebuild after new pushes
- The Settings footer shows `lane · build time (AEST/AEDT) · version (build)`, stamped by CI
- If workflows change, the documents must always be updated. This can also be confirmed with the user before editing, if there was a manual change required.

## Workflow Configuration Decisions

Use [pipeline.md](pipeline.md) and [.github/workflows/README.md](.github/workflows/README.md)
to choose the location and order of workflow changes:

- **`dev`:** app/build changes that follow normal promotion.
- **`master`:** shared CI/tooling/docs or default-branch triggers; use `ci/*` from `master` and merge back per pipeline.md.
- **Xcode Cloud:** remote settings such as triggers, Xcode versions and distribution; change these in App Store Connect. Remote-only changes need no code commit.

State the chosen location (`dev`, `master`, Xcode Cloud, or a combination),
whether a commit is needed, any remote prerequisite and its confirmation
status, and how the change will reach each affected branch. Validate the
relevant trigger/build behavior where possible and distinguish verified
results from pending remote checks.

If remote setup must happen first, draft the dependent edits but leave them
uncommitted until the setup is confirmed. If you cannot verify it, ask for that
specific confirmation. State the chosen target, whether a commit is needed,
and any pending prerequisite. Record confirmed operational changes in pipeline.md.
Edit AGENTS.md only, since CLAUDE.md imports it. Keep workflow tables and confirmed
operational details in pipeline.md.

---

## TestFlight notes

- Notes are generated from Git commit titles and build metadata; do not maintain release-cycle JSON, manual summaries or promotion entries.
- Use clear commit titles: they appear directly in TestFlight, including merge commits. The generator keeps newest commits and truncates older history to fit.
- Native Xcode Cloud PR builds use their actual target branch. Other builds use the lane defaults in `pipeline.md`; `TESTFLIGHT_TARGET_BRANCH` overrides them.
- Branch containment describes where the commit exists at build time. Do not present it as a reconstructed branch-creation or promotion history.
- Preview with `python3 ci_scripts/testflight_notes.py preview` and verify scripts with `python3 -m unittest discover -s ci_scripts -p 'test_testflight_notes.py'`. These commands do not build the app. `preview` only prints the notes; `--fetch` additionally updates local Git refs and full history.
