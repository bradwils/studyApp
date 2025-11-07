# Study App

This is the main iOS app for tracking study sessions, built with SwiftUI.

## Structure
- `Core/`: Main app components like `MainTabView` and `StudyAppApp`.
- `Features/`: Feature-specific views (e.g., Focus, Groups).
- `Models/`: Data models and stores (e.g., `SubjectStore`, `StudyTracking`).
- `Assets.xcassets/`: App icons and assets.
- `JSONs/`: Sample data files.

## Getting Started
1. Open `studyApp.xcodeproj` in Xcode.
2. Build and run on a simulator or device.

## Key Models
- `Subject`: Represents study subjects.
- `SubjectStore`: Manages subjects with persistence.
- `CompleteStudySession`: Tracks finished study sessions.