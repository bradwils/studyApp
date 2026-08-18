# 20/5 SwiftData Implementation Guide

> **Historical planning doc.** Written during the initial SwiftData migration; several steps below (model registration, relationships) have since landed in the code, sometimes in a different shape than proposed here (e.g. `SessionLocation` stayed its own `@Model` instead of being flattened). Treat this as a log of the migration's reasoning, not a live checklist — check `Models/StudySession.swift` and `App/StudyAppApp.swift` for current state.

This is the **project-specific migration playbook** for StudyApp — what to change, in which file, and why, in the order that makes sense.

---

## Current State at a Glance

| File | Status | Notes |
|---|---|---|
| `Models/Subject.swift` | ✅ Done | Proper `@Model final class` |
| `Models/Backend/Themes.swift` | ✅ Done | Proper `@Model final class` |
| `ViewModels/Settings/SubjectsEditorVM.swift` | ✅ Done | `@Observable`, context passed at call site |
| `Models/StudySession.swift` | ⚠️ | `@Model final class` — but `SessionLocation` not flattened, `breaks` missing `@Relationship`, `StudyBreak` still in same file using `TimeInterval` instead of `Date` |
| `ViewModels/StudyTrackingViewModel.swift` | ⚠️ | Compile errors fixed; all session methods are stubs — persistence not wired up yet |
| `ViewModels/PureFocusViewModel.swift` | ⚠️ | `@Published` removed ✅; still has `import SwiftUI` (should be removed per layer rules) |
| `ViewModels/Settings/ThemeSettingsViewModel.swift` | ❌ | Still `ObservableObject` + `@Published` + manual fetch |
| `ViewModels/SocialFeedViewModel.swift` | ❌ | Still `ObservableObject` + `@Published` |
| `App/StudyAppApp.swift` | ❌ | `modelContainer` missing `StudySession` and `StudyBreak` |

**The most important remaining work is Steps 2–5** — cleaning up the model files and wiring persistence into the VM. Steps 6–8 are smaller cleanups.

---

## Migration Checklist

- [x] **Step 1** — Fix `StudyTrackingViewModel` compile errors
- [ ] **Step 2** — Fix `StudyBreak` (separate file, use `Date` instead of `TimeInterval`, add inverse relationship)
- [ ] **Step 3** — Fix `StudySession` (flatten `SessionLocation`, add `@Relationship` to `breaks`, clean up init)
- [ ] **Step 4** — Register new models in the app container
- [ ] **Step 5** — Wire `StudyTrackingViewModel` to save/load via `ModelContext`
- [ ] **Step 6** — Fix `PureFocusViewModel` (remove `import SwiftUI`)
- [ ] **Step 7** — Migrate `ThemeSettingsViewModel` to `@Observable` + move fetch to View
- [ ] **Step 8** — Migrate `SocialFeedViewModel` to `@Observable`

---

## Step 1 — Fix `StudyTrackingViewModel` Compile Errors

**File:** `ViewModels/StudyTrackingViewModel.swift`

Before anything else, this file needs to compile. There are three errors:

**Error 1: `studyScore` is declared twice.**

```swift
// Remove this duplicate
var studyScore: Int? = nil // placeholder for user-rated session quality/score
// (keep the one on line ~42)
var studyScore: Int? = 0
```

Keep only one declaration. Use `var studyScore: Int? = nil` — `nil` is the right default (no score until session ends).

**Error 2: `interruptionCount: Int = nil` — `nil` can't be assigned to a non-optional `Int`.**

```swift
// Before
var interruptionCount: Int = nil

// After
var interruptionCount: Int = 0
```

**Error 3: `resumeSession()` is unclosed — it's missing a closing `}`.** The `endSession` function begins inside `resumeSession`'s body. Add the closing brace after `resumeSession`'s body ends.

Also remove unused imports — `CoreLocation` and `Combine` aren't needed until you actually use them.

**Verify:** `xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS` succeeds.

---

## Step 2 — Fix `StudyBreak` and Move to Its Own File

**Current file:** `Models/StudySession.swift`

`StudyBreak` is already `@Model final class` — good. But two things need fixing:

1. **`startedAt`/`endedAt` use `TimeInterval` — they should be `Date`.** `TimeInterval` is a raw `Double` (seconds since some reference point). Storing `Date` directly is the SwiftData-idiomatic choice: it's self-documenting, and computed properties like `duration` stay clean.

2. **It lives in `StudySession.swift` — move it to `Models/StudyBreak.swift`.** One type per file keeps the model layer navigable as it grows.

3. **Add the inverse relationship property** — `var session: StudySession?`. SwiftData needs both sides declared to maintain referential integrity.

**Create `Models/StudyBreak.swift`** with the corrected shape:

```swift
import Foundation
import SwiftData

@Model
final class StudyBreak {
    var startedAt: Date
    var endedAt: Date?
    var session: StudySession?  // inverse relationship — SwiftData keeps both sides in sync

    var duration: TimeInterval { (endedAt ?? startedAt).timeIntervalSince(startedAt) }

    init(startedAt: Date, endedAt: Date? = nil) {
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
```

Then delete the `StudyBreak` class from `StudySession.swift`.

**Verify:** The new file compiles. No lingering `StudyBreak` in `StudySession.swift`.

---

## Step 3 — Clean Up `StudySession`

**File:** `Models/StudySession.swift`

`StudySession` is already `@Model final class` — good. Three things still need fixing:

**1. Flatten `SessionLocation` into `StudySession`.** `SessionLocation` is its own `@Model`, but that's unnecessary overhead for three scalar fields. Delete `SessionLocation` and hoist its fields directly onto `StudySession` instead.

> The current `SessionLocation` is marked as a future placeholder anyway. A separate SwiftData entity adds a join table in the underlying SQLite for no benefit here.

**2. Add `@Relationship` to `breaks`.** Without it, the `[StudyBreak]` array isn't declared as a SwiftData relationship — it'll be treated as a codable blob (which may not behave correctly for `@Model` arrays). Declare it properly with a cascade delete rule.

**3. Simplify `init`.** The current init requires every property including optionals. Provide defaults so the VM can call `StudySession(subject: subject)` cleanly.

**Replace `StudySession.swift` with:**

```swift
import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID = UUID()
    var subject: Subject?
    var subjectName: String?
    var startedAt: Date = Date.now
    var endedAt: Date?
    var lastPausedAt: Date?
    var totalActiveDuration: TimeInterval = 0
    var totalBreakDuration: TimeInterval = 0
    var friends: [String] = []
    var locationDescription: String?
    var latitude: Double?
    var longitude: Double?
    var studyScore: Int?
    var notes: String?
    var interruptionCount: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \StudyBreak.session)
    var breaks: [StudyBreak] = []

    var totalElapsed: TimeInterval {
        if let endedAt { return endedAt.timeIntervalSince(startedAt) }
        return Date().timeIntervalSince(startedAt)
    }

    init(subject: Subject? = nil) {
        self.subject = subject
        self.subjectName = subject?.name
    }
}
```

Delete `SessionLocation` and `StudyBreak` from this file — `SessionLocation` is gone (flattened), `StudyBreak` moves to its own file in Step 2.

> **Why `deleteRule: .cascade`?** Breaks only exist in the context of a session. When the session is deleted, the breaks should go with it automatically — no manual cleanup needed.

**Verify:** Both `StudySession.swift` and `StudyBreak.swift` compile without errors.

---

## Step 4 — Register New Models in the Container

**File:** `App/StudyAppApp.swift`

SwiftData needs to know about every model you want to persist. The container declaration is the single place where you register them all. Without this, `context.insert()` will silently fail.

```swift
// Before
.modelContainer(for: [AppTheme.self, Subject.self])

// After
.modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self])
```

> **Think of `.modelContainer(for:)` as telling SwiftData "create a database table for each of these types."** If a type isn't in this list, there's no table — and no persistence.

**Verify:** The app launches without a crash. (A missing registration usually crashes immediately on launch with a "model not found in schema" error.)

---

## Step 5 — Wire `StudyTrackingViewModel` to Persistence

**File:** `ViewModels/StudyTrackingViewModel.swift`

Now that `StudySession` is a `@Model`, the VM's methods can create, mutate, and save sessions. The pattern to follow is the same one already used in `SubjectsEditorVM.swift` — each method that touches persisted data takes `context: ModelContext` as a parameter.

> **Why pass `context` at the call site instead of storing it in `init`?** A `ModelContext` is tied to a specific moment in the app's lifecycle. Storing it in a VM creates subtle bugs if the context ever becomes stale. Passing it at call time keeps the VM simple, and it matches how SwiftUI expects you to work. This is the pattern the project has already committed to.

Clean up the VM's stored properties to match the new `StudySession` shape:

```swift
import Foundation
import SwiftData

@Observable
final class StudyTrackingViewModel {
    var selectedSubject: Subject? = nil
    var activeSession: StudySession? = nil
    var studySessionPaused: Bool = false
    private let breakThreshold: TimeInterval = 60 * 3

    func startSession(subject: Subject? = nil, context: ModelContext) {
        let session = StudySession(subject: subject)
        activeSession = session
        studySessionPaused = false
        context.insert(session)
    }

    func pauseSession() {
        guard let session = activeSession, !studySessionPaused else { return }
        let now = Date()
        session.totalActiveDuration += now.timeIntervalSince(session.startedAt)
        session.lastPausedAt = now
        session.isPaused = true
        studySessionPaused = true
    }

    func resumeSession(context: ModelContext) {
        guard let session = activeSession, let pausedAt = session.lastPausedAt else { return }
        let now = Date()
        let pauseDuration = now.timeIntervalSince(pausedAt)

        if pauseDuration >= breakThreshold {
            // Pause was long enough to count as a break — log it
            let studyBreak = StudyBreak(startedAt: pausedAt, endedAt: now)
            session.breaks.append(studyBreak)
            session.totalBreakDuration += pauseDuration
        }

        session.isPaused = false
        session.lastPausedAt = nil
        studySessionPaused = false
    }

    func togglePause(context: ModelContext) {
        studySessionPaused ? resumeSession(context: context) : pauseSession()
    }

    func endSession(score: Int? = nil, notes: String? = nil, context: ModelContext) {
        guard let session = activeSession else { return }
        if !studySessionPaused {
            session.totalActiveDuration += Date().timeIntervalSince(
                session.lastPausedAt ?? session.startedAt
            )
        }
        session.endedAt = Date()
        session.studyScore = score
        session.notes = notes
        try? context.save()
        activeSession = nil
        studySessionPaused = false
    }

    func cancelActiveSession(context: ModelContext) {
        guard let session = activeSession else { return }
        context.delete(session)
        activeSession = nil
        studySessionPaused = false
    }

    func addInterruption() {
        activeSession?.interruptionCount += 1
    }
}
```

**Verify:** In the view that calls these methods, pass `modelContext` from `@Environment(\.modelContext)`:

```swift
vm.startSession(subject: vm.selectedSubject, context: modelContext)
vm.endSession(score: selectedScore, context: modelContext)
```

To confirm sessions are actually being saved, add this temporary debug line to any view:

```swift
@Query var allSessions: [StudySession]
// ...
Text("Sessions saved: \(allSessions.count)")  // remove when done testing
```

---

## Step 6 — Fix `PureFocusViewModel`

**File:** `ViewModels/PureFocusViewModel.swift`

`@Published` is already removed — `@Observable` is in place and all properties are plain `var`. One thing remains:

**Remove `import SwiftUI`.** VMs shouldn't import SwiftUI — they don't know they're powering a UI, which is the whole point of the MVVM split. `import Combine` is correct to keep (it's where `AnyCancellable` comes from, used for the timer publisher).

```swift
// Remove this
import SwiftUI

// Keep this
import Combine
```

**No SwiftData needed here.** `PureFocusViewModel` manages transient timer state only. When a focus session completes, it's `StudyTrackingViewModel.endSession(context:)` that saves to the database — not the focus timer.

**Verify:** File compiles. Timer still starts, pauses, and stops in the focus view.

---

## Step 7 — Migrate `ThemeSettingsViewModel` to `@Observable` + Move Fetch to View

**File:** `ViewModels/Settings/ThemeSettingsViewModel.swift`

Two problems here:
1. It's still `ObservableObject` + `@Published`.
2. It holds `@Published var themes: [AppTheme]` and manually fetches via `FetchDescriptor` in `refreshThemes()`. This is the old way — it means the list only updates when you remember to call `refreshThemes()`. That's exactly the problem `@Query` solves.

> **Why `@Query` in the View, not the VM?** `@Query` is a SwiftUI property wrapper — it can only live inside a `View` struct. It hooks directly into SwiftData's observation system and re-renders the View the instant data changes. A VM holding a fetched array manually never gets that automatic signal.

**Migrate the VM:**

```swift
import SwiftUI
import SwiftData

@Observable
final class ThemeSettingsViewModel {
    var selectedColor: Color = .white

    struct ThemeTemplate: Identifiable {
        let id = UUID()
        let name: String
        let primary: Color
        let secondary: Color
        let accent: Color
    }

    let defaultThemes: [ThemeTemplate] = [
        ThemeTemplate(name: "Summer", primary: .yellow, secondary: .orange, accent: .red),
        ThemeTemplate(name: "Winter", primary: .gray, secondary: .blue, accent: .white),
        ThemeTemplate(name: "Dummy", primary: .black, secondary: .green, accent: .blue)
    ]

    func createTheme(named name: String, primary: Color, secondary: Color, accent: Color, using context: ModelContext) {
        context.insert(AppTheme(name: name, primary: primary, secondary: secondary, accent: accent))
    }

    // Call this once on first launch to seed defaults
    func ensureDefaultsExist(existingCount: Int, using context: ModelContext) {
        guard existingCount == 0 else { return }
        for template in defaultThemes {
            context.insert(AppTheme(name: template.name, primary: template.primary, secondary: template.secondary, accent: template.accent))
        }
    }
}
```

**In the View, add `@Query` and call `ensureDefaultsExist` once:**

```swift
struct ThemeSettingsView: View {
    @Query(sort: \AppTheme.name) var themes: [AppTheme]
    @Environment(\.modelContext) var modelContext
    @State private var vm = ThemeSettingsViewModel()

    var body: some View {
        List(themes) { theme in
            Text(theme.name)
        }
        .task {
            // Runs once when the view appears; seeds defaults if empty
            vm.ensureDefaultsExist(existingCount: themes.count, using: modelContext)
        }
    }
}
```

Delete `refreshThemes()`, `bootstrap()`, and the `@Published var themes` property from the VM entirely.

**Verify:** Settings screen displays themes. Adding a new theme via `createTheme(named:...)` updates the list instantly without any manual refresh call.

---

## Step 8 — Migrate `SocialFeedViewModel` to `@Observable`

**File:** `ViewModels/SocialFeedViewModel.swift`

No SwiftData needed — the social feed is remote/network data. This is purely a pattern cleanup.

```swift
// Before
final class SocialFeedViewModel: ObservableObject {
    @Published var items: [SocialFeedItem]
    @Published var currentSessionTime: String
    // ...
}

// After
@Observable
final class SocialFeedViewModel {
    var items: [SocialFeedItem]
    var currentSessionTime: String
    // ...
}
```

Remove `import Combine`. Remove `import SwiftUI` if it was only there for `ObservableObject`. The rest of the VM stays unchanged.

**Verify:** Social feed view renders sample items. No observable-related warnings in the console.

---

## What We're Not Migrating (and Why)

| File | Reason |
|---|---|
| `Models/User.swift` (`UserProfile`) | Needs auth/backend design first. Premature to lock in a SwiftData shape for something that depends on external systems. |
| `Models/SocialFeed.swift`, `Models/ListItem.swift` | Remote display DTOs. They'll come from a network layer, not a local database. |
| `Models/RemoteUser.swift` | Network model — `Codable` is the right tool, not SwiftData. |
| `Models/StudySession.swift` (`SessionLocation` struct) | Deleted — flattened into `StudySession` directly (Steps 2–3). |

---

## Recurring Patterns: Your Quick Reference

These rules apply throughout the codebase. When in doubt, check `SubjectsEditorVM.swift` — it's already the canonical correct example.

**Models**
- Always `@Model final class` — never a struct.
- Provide default values for all properties so SwiftData can create rows without an explicit init.
- Arrays of `@Model` types become relationships — declare them with `@Relationship`.
- Arrays of primitive types (`String`, `Int`, `Double`) are fine as-is.

**ViewModels**
- `@Observable` class — never `ObservableObject`.
- Never `@Published` inside `@Observable` — plain `var` is all you need.
- No `import SwiftUI` — VMs don't know they're powering a UI.
- Methods that mutate persistent data take `context: ModelContext` as a parameter — never stored in `init`.

**Views**
- `@Query` for reads — it's live, it auto-refreshes, it belongs in the View.
- `@Environment(\.modelContext)` for writes — always available because the app root sets up `.modelContainer(for:)`.
- Initialize VMs non-optionally: `@State private var vm = MyVM()` — no optional unwrapping needed.
- Pass `modelContext` to VM methods at call time: `vm.save(context: modelContext)`.

**App Root**
- Every `@Model` type must be listed in `.modelContainer(for:)` in `StudyAppApp.swift`. Missing = no table = silent failure on insert.

---

## End-to-End Verification

Once all steps are done, run through this checklist:

**Build:**
```bash
xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS
```

**Session persistence:**
1. Start a session, pause it, resume it, end it.
2. Force-quit and relaunch the app.
3. Add a temporary `@Query var sessions: [StudySession]` + `Text("Sessions: \(sessions.count)")` to any view — the count should persist across launches.

**Theme persistence:**
1. Open Settings → add a new theme.
2. Force-quit and relaunch — the theme should still be there.
3. Confirm the list updates immediately after adding (no refresh button needed).

**Clean up debug lines** before shipping — any `Text("Sessions: \(count)")` added for testing.
