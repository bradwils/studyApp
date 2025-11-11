# StudyApp Overview

## Purpose
StudyApp is a SwiftUI-based iOS application that surfaces social study activity, focus tools, group collaboration, and configurable modes through a tab-driven experience.

## Architecture
The app follows SwiftUI industry best practices with a clean, organized structure:

- **App Layer**: Entry point and main navigation
- **View Layer**: All UI components organized by feature
- **Model Layer**: Data models and business logic
- **Resources**: Assets and sample data

## High-Level Flow
- `StudyAppApp` boots the SwiftUI app and hosts `MainTabView`.
- `MainTabView` builds the global `TabView`, with each feature inside its own `NavigationStack`.
- Feature screens live under `Views/` organized by feature area (Social, Focus, Groups, Modes, Settings, Profile).
- Data models and stores in `Models/` provide shared data across features.
- `Resources/` contains assets and sample data for prototyping.

## Folder Structure
```
studyApp/
├── App/                    # App entry point and main navigation
│   ├── StudyAppApp.swift   # App entry point
│   └── MainTabView.swift   # Tab navigation
├── Views/                  # All view files organized by feature
│   ├── Social/             # Social feed and components
│   ├── Focus/              # Focus mode views
│   ├── Groups/             # Study groups
│   ├── Modes/              # Study modes
│   ├── Settings/           # Settings and preferences
│   └── Profile/            # User profiles
├── Models/                 # Data models and stores
│   ├── Subject.swift
│   ├── SubjectStore.swift
│   ├── StudyTracking.swift
│   └── SocialFeed.swift
└── Resources/              # Assets and data
    ├── Assets.xcassets/
    └── SampleData/
```

## Features
- **Social**: Feed of study activity with user profiles
- **Focus**: Focus mode tools and timers
- **Groups**: Collaborative study groups
- **Modes**: Configurable study modes
- **Settings**: App settings and subject management
- **Profile**: User profile details and statistics

## Data Models
- `Subject`: Represents study subjects with persistence
- `SubjectStore`: Manages subject data with local storage
- `CompleteStudySession`: Tracks completed study sessions
- `StartStudyTimer`: Manages active study timers
- `ListItem`: Social feed item model

## Navigation
- Tab-based navigation between main features
- NavigationStack within each tab for feature-specific flows
- Profile detail views accessible from social feed

