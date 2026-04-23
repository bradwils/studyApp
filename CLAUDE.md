# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build & run:** Open `studyApp.xcodeproj` in Xcode → `Cmd+R` (simulator or device). No package manager or build scripts.

**Run all tests:**
```
xcodebuild test \
  -project studyApp.xcodeproj \
  -scheme studyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Run a single test:**
```
xcodebuild test \
  -project studyApp.xcodeproj \
  -scheme studyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:studyAppTests/studyAppTests/testAddSubjectPersistsToDisk
```

Tests use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`). Not XCTest — do not mix the two.

## Architecture

SwiftUI iOS app, MVVM-ish. Entry point: `StudyAppApp` → `MainTabView` (5-tab `TabView`, each tab in its own `NavigationStack`).

```
StudyAppApp
└── MainTabView (TabView)
    ├── Debug tab    → SettingsView
    ├── Social tab   → SocialFeedView
    ├── Focus tab    → StudyTrackingView → PureFocusView (pushed)
    ├── Groups tab   → GroupsView (stub)
    └── Modes tab    → ModesView (stub)
```

**Two separate persistence layers:**
- JSON files in the Documents directory — `UserProfileStore` owns `userProfile.json` (profile + subjects + session list). Written atomically on every mutation.
- SwiftData — `AppTheme` model only. The `ModelContainer` is created at app root in `StudyAppApp`.

**State ownership:**
- `UserProfileStore` is currently a singleton (`UserProfileStore.shared`). `plan.md` describes a planned migration to `@EnvironmentObject` injection — do not add new singleton references to it.
- Each feature view creates its own `@StateObject` view model. View models hold `@Published` state; views are declarative and call VM methods for all mutations.
- `StudyTrackingViewModel` is the authoritative source for the active session. Views must not duplicate its timer math.

**Focus flow (two distinct modes):**
1. `StudyTrackingView` / `StudyTrackingViewModel` — count-up, open-ended session. Tracks `activeSession: StudySession`, accumulates `totalActiveDuration` manually on pause/resume. A pause ≥ 3 minutes (`breakThreshold`) is recorded as a `StudyBreak`.
2. `PureFocusView` / `PureFocusViewModel` — count-down timer with a fixed duration. Uses `Timer.publish(every: 0.1)` via Combine. Progress drives `TimerGradientBackground` (black→white animated gradient). The `DurationPicker` binding to `currentTimerTotalDuration` is currently incomplete (see TODO.txt #4).

**Social feed:** Entirely static mock data in `SocialFeedViewModel.sampleItems`. No networking exists yet; `RemoteUser` and `Resources/SampleData/` are placeholders for a future backend.

## Key model relationships

```
UserProfile
├── subjects: [Subject]          — user's registered study subjects
├── studySessions: [StudySession] — archived (UserProfile.storeStudySessionsLocally() is UNTESTED)
└── auth: AuthState              — AuthProvider enum (.anon until sign-in is wired)

StudySession
├── subject: Subject?
├── breaks: [StudyBreak]         — only pauses ≥ 3 min are recorded here
├── totalActiveDuration          — accumulated by StudyTrackingViewModel on each pause
└── runningActiveDuration        — computed; adds live elapsed time if not paused
```

`SocialFeedItem` and `ListItem` are duplicates — `ListItem` is the older type and should not be extended.

## Conventions

- Use `#Preview` macros for all new views.
- New UI goes in a feature folder under `Views/`; reusable primitives go in `Views/Components/`.
- Time display always uses `TimeInterval.formattedClock` (`Extensions/TimeInterval+Formatting.swift`).
- `#if DEBUG` guard seeds sample data in `UserProfileStore` — keep debug-only code behind this flag.
- `AppTheme` colors are stored as hex strings internally; use `ThemeColorHex` utilities for conversion.

## Active known issues (TODO.txt)

- **StudyItemCard:** Three visual variants coexist (`accentBar`, `bubbleCard`, `compactRow`) — one must be chosen and the others deleted.
- **CustomBottomSheet:** Uses `.regularMaterial` as a placeholder; true glass effect blocked by SwiftUI limitation on `UnevenRoundedRectangle`.
- **DurationPicker:** Binding to `PureFocusViewModel.currentTimerTotalDuration` is not wired correctly.
- **Tab bar snap:** Hidden via `.toolbar(.hidden, for: .tabBar)` in `PureFocusView`; monitor for layout jump on back-navigation.
