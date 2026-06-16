# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Quick Start

**Build:**
```bash
xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS
```

**Run tests:**
```bash
xcodebuild test -project studyApp.xcodeproj -scheme studyApp
```

---

## Architecture Overview

SwiftUI iOS app — social study tracking, focus timer, and group collaboration. MVVM with SwiftData for persistence (migration in progress from JSON/Stores).

**Layers:**
- `App/` — entry point (`StudyAppApp.swift`) and tab navigation (`MainTabView.swift`)
- `Models/` — SwiftData `@Model final class` definitions; pure data only
- `ViewModels/` — `@Observable final class`; business logic and form state
- `Views/` — SwiftUI views organized by feature (Social, Focus, Groups, Settings, Profile)
- `ViewModels/SubjectStore.swift`, `UserProfileStore.swift` — legacy JSON persistence, being phased out

See [AppOverview.md](docs/AppOverview.md) for full folder structure.

---

## Key Architectural Decisions

### SwiftData Migration (In Progress)

Models are migrating from manual JSON (`Store` singletons) to SwiftData.

- `Subject.swift`, `StudySession.swift` ✅ `@Model final class`
- `StudyAppApp.swift` ✅ `.modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, SessionLocation.self])`
- Several views still reference legacy `Store` singletons — migrate with the pattern below

**Migration pattern:**
1. Create `ViewModels/Feature/FeatureVM.swift` as `@Observable final class`
2. Move form state and CRUD methods into VM; methods accept `ModelContext` as a parameter (not stored)
3. In the view: `@Query` for reads, `@Environment(\.modelContext)` for writes
4. Initialize VM non-optionally: `@State private var vm = FeatureVM()`
5. Drop the old `Store` dependency

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

- `deleteRule: .cascade` — "I own this; delete it with me"
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

---

## Code Style

- Comments only for non-obvious *why* — never for *what* the code does
- No docstrings; if the method name needs explanation, rename it
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

- `StudyTrackingViewModel` references properties not yet on `StudySession` (`isPaused`, `lastResumedAt`, `companions`) — these need to be added or the VM updated
- `UserProfileStore`, `SubjectStore` are legacy — avoid new dependencies on them
- `AppSettings.swift` (deleted on current branch) — settings view in flux

See [TODO.txt](TODO.txt) for deferred UI decisions.

---

## Git Workflow

- Main branch: `master`
- Feature branches: descriptive names (`timer-fix`, `swiftdata-session-tracking`)
- No force pushes to `master`

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
