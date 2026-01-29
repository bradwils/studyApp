# Copilot instructions for StudyApp

## Architecture overview
- SwiftUI-only app. Entry point is `StudyAppApp` which loads `MainTabView` with a `TabView` + `NavigationStack` per tab (see App/StudyAppApp.swift and App/MainTabView.swift).
- Feature-first views live under Views/* (Focus, Social, Groups, Modes, Settings, Profile). Smaller UI building blocks sit in Views/Components (e.g., `ActiveSubjectList`, `FocusIntensitySlider`).
- MVVM-ish: views own `@StateObject` view models and react to `@Published` updates (see ViewModels/*). Keep views declarative and move logic into view models.

## Data flow & state
- Session tracking logic is centralized in `StudyTrackingViewModel` (start/pause/resume/end, break threshold logic). Views should call its methods instead of duplicating timer math (see ViewModels/StudyTrackingViewModel.swift; used in Views/Focus/StudyTrackingView.swift).
- `SubjectStore` is the local persistence layer for subjects. It reads/writes a JSON file in the app documents directory and seeds sample subjects under `#if DEBUG` (see ViewModels/SubjectStore.swift). Settings/SubjectsEditor and Focus/StudyTrackingView rely on this store.
- Social feed is currently static: `SocialFeedViewModel` ships with `sampleItems` and no networking (see ViewModels/SocialFeedViewModel.swift and Views/Social/*).
- Time formatting for display uses `TimeInterval.formattedClock` (see Extensions/TimeInterval+Formatting.swift).

## Project conventions
- Use SwiftUI previews (`#Preview`) for most views as shown across Views/*.
- When adding new UI, prefer feature folders under Views/ and reuse Components/ where possible.
- Maintain the existing one-way flow: views send user intent to the view model; view models publish state back.

## Workflows
- Open studyApp.xcodeproj in Xcode and build/run on a simulator or device (per README.md).
- No automated tests found in the repository.

## Integration points
- Local JSON persistence only (no network layer yet). `Resources/SampleData/` exists for mock data.
