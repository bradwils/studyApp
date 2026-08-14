# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Quick Start

**Build and run:**
```bash
xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS
open studyApp.xcodeproj  # then run from Xcode
```

**Run tests:**
```bash
xcodebuild test -project studyApp.xcodeproj -scheme studyApp
```

---

## Architecture Overview

StudyApp is a **SwiftUI-based iOS app** that combines social study tracking, focus timer tools, and group collaboration. It follows **MVVM** pattern with **SwiftData** for persistence (migration in progress).

### What is MVVM?
MVVM separates UI concerns from business logic. **Model** = your data (subjects, sessions), **View** = what the user sees (SwiftUI), **ViewModel** = the glue that transforms model data into UI-ready state. This keeps Views simple and testable.

**Main layers:**
- **App**: Entry point (`StudyAppApp.swift`) and tab navigation (`MainTabView.swift`)
- **Views**: UI organized by feature (Social, Focus, Groups, Settings, Profile) — displays data and responds to user taps
- **ViewModels**: State management and business logic — holds form state, handles CRUD operations, transforms data for display
- **Models**: Data models with SwiftData (`@Model final class`) — definitions of your data, persisted to disk
- **Resources**: Assets and sample data

See [AppOverview.md](docs/AppOverview.md) for the full folder structure and [SwiftData.md](studyApp/App/docs/SwiftData.md) for data layer patterns.

---

## Key Architectural Decisions

### 1. SwiftData Migration (In Progress)

**Current state:** Models are being migrated from manual JSON persistence to SwiftData.

- `Subject.swift` ✅ Already a `@Model final class`
- `StudyAppApp.swift` ✅ Already has `.modelContainer(for: [...])`
- Views still need migration to use `@Query` and `modelContext`

**What is SwiftData?**
SwiftData is Apple's modern persistence layer (like a lightweight database). Instead of writing data to JSON files manually, SwiftData handles saving/loading for you. It uses a **container** (the actual database file on disk) and a **context** (your handle to read/write data in the current session).

**How it works:**
- `modelContainer` in app root = creates/manages the database file (created once in `StudyAppApp`, shared across the entire app)
- `@Query var items: [Item]` in views = a live, auto-updating list that re-renders whenever the underlying data changes (powered by SwiftData)
- `@Environment(\.modelContext)` in views = your write handle — use this to insert, update, or delete data in the current session
- When you modify data via `modelContext` and call `save()`, it persists to disk

See [SwiftData.md](studyApp/App/docs/SwiftData.md) for detailed patterns.

### 2. MVVM + SwiftData Pattern

**Why split into ViewModel and View?**
- **ViewModel** = the business logic (managing form state, saving to database)
- **View** = just displaying data and calling ViewModel methods when user taps buttons

This keeps Views simple and reusable. A View doesn't need to know *how* data is saved; it just calls a ViewModel method.

**ViewModel responsibilities:**
- Hold transient UI state (simple `var` properties for forms, like `newSubjectName` while the user is typing — `@Observable` tracks changes automatically)
- Provide methods for CRUD operations (Create, Read, Update, Delete) that accept `ModelContext` as a parameter
- Use `@Observable` macro (modern replacement for `@ObservableObject` — SwiftUI watches changes and re-renders)
- NO `@State` in classes (only in `struct View`) — `@Observable` handles change tracking

**View responsibilities:**
- Display data via `@Query` (this *must* be in views, not ViewModels — SwiftUI needs direct access to re-render)
- Initialize the ViewModel non-optionally (the `modelContext` is always available via `@Environment` at view declaration time)
- Pass `modelContext` to ViewModel methods when calling them — dependency injection at call site
- Handle navigation and UI layout — the "what should I show" logic

**Example split:**
```swift
// SubjectsEditorVM.swift — the business logic
@Observable
class SubjectsEditorVM {
    // Form state: @Observable watches these automatically (no @State needed in classes)
    var newSubjectName: String = ""
    var newSubjectCode: String = ""
    
    var canAddSubject: Bool {
        newSubjectName.count > 0 && newSubjectCode.count > 0
    }
    
    // Context passed at call time, not stored. Keeps VM simple to initialize
    // and easier to test (can pass different contexts if needed)
    func addSubject(context: ModelContext) {
        guard canAddSubject else { return }
        context.insert(Subject(name: newSubjectName, code: newSubjectCode.uppercased()))
        newSubjectName = ""
        newSubjectCode = ""
    }
    
    func removeSubject(_ subject: Subject, context: ModelContext) {
        context.delete(subject)
    }
}

// SubjectsEditor.swift — the view/UI layer
struct SubjectsEditor: View {
    // Get all subjects from the database — automatically updates when data changes
    @Query var subjects: [Subject]
    
    // Get write access to the database (always available from app root's .modelContainer)
    @Environment(\.modelContext) var modelContext
    
    // ViewModel is non-optional because modelContext is guaranteed at view initialization.
    // The app root sets up .modelContainer(), which provides modelContext to all child views.
    // No need for .onAppear initialization or optional unwrapping.
    @State private var vm = SubjectsEditorVM()
    
    var body: some View {
        VStack {
            List {
                ForEach(subjects) { subject in
                    Text(subject.name)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        vm.removeSubject(subjects[index], context: modelContext)
                    }
                }
            }
            
            TextField("Subject name", text: $vm.newSubjectName)
            
            Button("Add") {
                vm.addSubject(context: modelContext)
            }
            .disabled(!vm.canAddSubject)
        }
    }
}
```

### 3. Layer Rules

**Models layer:**
- Only data definitions (`@Model final class` with `@Attribute` and `@Relationship` decorators)
- No business logic, no UI imports — models don't "do" anything, they just *are* data
- Use SwiftData attributes: `@Attribute(.unique)` to enforce database constraints, `@Relationship` to link models together
- Example: `Subject` is just a data container with a name and code; it doesn't fetch or save itself

**ViewModels:**
- `@Observable` classes (modern replacement for `@ObservableObject`), not the old `@ObservableObject` macro
- Hold form state (like temporary user input) as simple `var` properties — NO `@State` (that's only for Views)
- Provide CRUD methods that accept `ModelContext` as a parameter, not stored in init — this keeps VMs simple and non-optional in Views
- No SwiftUI imports (no `import SwiftUI`) — just foundation imports; the ViewModel doesn't know it's powering UI

**Views:**
- SwiftUI-only state management: `@State` for transient UI state, `@Query` for database queries
- Initialize ViewModels non-optionally: `@State private var vm = SubjectsEditorVM()` — `modelContext` is guaranteed via `@Environment` from the app root
- Pass `modelContext` to ViewModel methods at call time: `vm.addSubject(context: modelContext)` — keeps the ViewModel simple and testable
- Use previews with `.modelContainer(for: Model.self, inMemory: true)` to test without touching the real database
- Views are "dumb" about persistence — they just display data and call ViewModel methods

**Stores (legacy, phasing out):**
- `UserProfileStore`, `SubjectStore` use old JSON persistence (reading/writing JSON files manually)
- Being replaced by SwiftData models in Views + ViewModels
- Avoid adding new dependencies on these — if you're touching a Store, consider migrating to SwiftData instead

---

## Common Tasks

### Adding a New Model

1. Create in `Models/` as `@Model final class`
2. Add to `.modelContainer(for: [...])` in `StudyAppApp.swift` — this tells SwiftData to create a table for this model
3. Use `@Attribute(.unique)` on ID fields to prevent duplicates, provide default values for all properties

**Why?** Models are the source of truth. SwiftData needs to know about every model you want to persist, so the container must include it.

### Migrating a View to SwiftData

1. Create a ViewModel (`ViewModels/Feature/FeatureVM.swift`) to hold form state and CRUD logic as an `@Observable` class
2. Move form state (like `newName: String = ""`) and methods (like `addItem(context:)`) into the VM — methods accept `ModelContext` as a parameter
3. In the View: add `@Query var items` to fetch data, `@Environment(\.modelContext)` to get database write access
4. Initialize the ViewModel non-optionally: `@State private var vm = FeatureVM()` — pass `modelContext` to methods when calling them
5. Remove dependencies on old `Store` singletons
6. Test with previews to ensure data flows correctly (add `.modelContainer(for: Model.self, inMemory: true)`)

**Why?** Old Stores used JSON files and singletons. SwiftData is faster and simpler. Views become lighter and easier to test. Non-optional VMs eliminate unwrapping clutter.

### Writing Previews with SwiftData

```swift
#Preview {
    SubjectsEditor()
        // Create an in-memory database for preview (not saved to disk)
        // This lets you test UI without touching the real database
        .modelContainer(for: Subject.self, inMemory: true)
}
```

**Why?** Previews need a valid `.modelContainer`, or SwiftUI can't render. `inMemory: true` keeps preview databases isolated from real data.

### Filtering with @Query

```swift
@Query(
    // Filter: only subjects whose name contains "Math"
    filter: #Predicate<Subject> { $0.name.contains("Math") },
    // Sort: by createdAt date, ascending
    sort: \Subject.createdAt
)
var mathSubjects: [Subject]
```

**Why?** `@Query` fetches *all* data by default, which is slow. Filtering and sorting at the database level is more efficient than fetching everything and filtering in Swift.

---

## Current Maintenance Notes

See [TODO.txt](TODO.txt) for deferred UI decisions and [plan.md](plan.md) for legacy architecture decisions (some now outdated by SwiftData migration).

**Active work:**
- Migrating Views to use `@Query` and `modelContext` directly
- Phasing out `UserProfileStore` and `SubjectStore` JSON persistence


---

## Code Style

- **Minimal comments for simple code** (clean names explain *what*); add comments only when the *why* is non-obvious
  - ❌ `// Loop through subjects` — obvious
  - ✅ `// Filter active subjects only; inactive ones cause perf issues in the list` — explains a constraint
- No docstrings for methods — if the method name is unclear, rename the method
- Use property names that are self-explanatory: `newSubjectName` is clearer than `tempName` or `n`
- Prefer `final class` for all models — prevents accidental subclassing and keeps inheritance boundaries clear
- Group related state together in ViewModels — `newSubjectName` and `newSubjectCode` belong near each other
- **When adding complex logic, comment it:** SwiftData queries, database migrations, or non-obvious Swift patterns should have a comment explaining the intent

---

## Debugging SwiftData

**Check saved data:**
```swift
@Query var allSubjects: [Subject]
// Temporarily add this to a view to see how many subjects exist
Text("Subjects: \(allSubjects.count)")
```

**Why?** If data isn't persisting, check the count. If it's always 0, data isn't being saved. If the count is stale, the View isn't observing `@Query` correctly.

**Force save:**
```swift
// After modifying modelContext (insert/delete), explicitly save to disk
try? modelContext.save()
```

**Why?** SwiftData doesn't auto-save; you must call `save()`. Without it, changes exist in memory but disappear when the app closes.

**Delete all data (testing):**
```swift
// Wipe all subjects from the database — useful for testing
try? modelContext.delete(model: Subject.self)
try? modelContext.save()
```

**Why?** During development, you may want a clean slate. This removes all data for a model type. Call `save()` after to persist the deletion to disk.

**Common issues:**
- Data appears in one session but vanishes when you restart → you forgot to call `save()`
- Changes don't appear in the UI → `@Query` wasn't used, or the ViewModel didn't trigger a re-render
- Two parts of the app see different data → multiple `modelContext`s exist; ensure only one is used per app lifecycle

---

## External Docs

- [App overview](docs/AppOverview.md) — feature description and folder structure
- [SwiftData guide](studyApp/App/docs/SwiftData.md) — models, relationships, queries, patterns
- [Settings documentation](studyApp/App/docs/AppSettings.md) — user preferences and theme

---

## Git Workflow

- Main branch: `master`
- Feature branches: descriptive names (`timer-fix`, `swiftdata-migration`, etc.)
- Commits: short, focused changes with clear messages
- No force pushes to `master`

# General Behavioural Guidelines

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

Always update build: String (in StudyAppApp.swift) with the name of the branch, if you create a new one.
