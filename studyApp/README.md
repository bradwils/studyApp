# Study App

This is the main iOS app for tracking study sessions, built with SwiftUI.

## Structure

The app follows SwiftUI industry best practices with a clean, organized structure:

- `App/`: Main app entry point and tab navigation
  - `StudyAppApp.swift`: App entry point
  - `MainTabView.swift`: Main tab navigation
- `Views/`: All view files organized by feature
  - `Social/`: Social feed and related components
  - `Focus/`: Focus mode views
  - `Groups/`: Study groups views
  - `Modes/`: Study modes configuration
  - `Settings/`: Settings and preferences
  - `Profile/`: User profile views
- `Models/`: Data models and stores
  - `Subject.swift`: Subject model
  - `SubjectStore.swift`: Subject persistence management
  - `StudyTracking.swift`: Study session tracking models
  - `SocialFeed.swift`: Social feed data models
- `Resources/`: Assets and data files
  - `Assets.xcassets/`: App icons and assets
  - `SampleData/`: Sample JSON data

## Getting Started
1. Open `studyApp.xcodeproj` in Xcode.
2. Build and run on a simulator or device.

## Key Models
- `Subject`: Represents study subjects.
- `SubjectStore`: Manages subjects with local persistence.
- `CompleteStudySession`: Tracks finished study sessions.