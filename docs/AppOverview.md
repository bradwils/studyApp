# StudyApp Overview

## Purpose
StudyApp is a SwiftUI-based iOS application that surfaces social study activity, focus tools, group collaboration, and configurable modes through a tab-driven experience.

## High-Level Flow
- `StudyAppApp` boots the SwiftUI app and hosts `MainTabView`.
- `MainTabView` builds the global `TabView`, pushing each feature inside its own `NavigationStack`.
- Individual feature screens (e.g., `SocialFeedView`, `FocusView`) live under `Features/` and pull in reusable UI from `Components/` and shared data from `Models/`.
- Local JSON assets (e.g., `JSONs/mainListItems/sample1.json`) provide mock data for prototyping.

## Folder Responsibilities
- `Core/` — App entry point (`StudyAppApp`) and cross-feature scaffolding such as `MainTabView`.
- `Features/` — Feature-specific screens and logic. Current subfolders: Social, Focus, Groups, Modes, Profile.
- `Components/` — Reusable SwiftUI views shared between features (e.g., cards, headers).
- `Models/` — Shared data models and stores that multiple features consume (e.g., `StudyTracking` for session data).
- `JSONs/` — Local JSON fixtures backing UI prototyping or sample content.
- `Assets.xcassets/` — Color sets and app icon resources.

## Feature Snapshot
- **Social**: `SocialFeedView` renders a feed of study activity using `StudyItemCard` and navigation into `StudyMemberDetailView`.
- **Focus**: `FocusView` placeholder for focus-mode functionality surfaced via its own tab.
- **Groups**: `GroupsView` placeholder for collaboration flows.
- **Modes**: `ModesView` placeholder for future study modes.
- **Profile**: `StudyMemberDetailView` displays details on a selected study member.

## Shared Components & Models
- `Components/Social/DashboardHeader.swift`: Summary header for the social dashboard (streaks, current session).
- `Components/Social/StudyItemCard.swift`: Reusable card showing an individual's study snapshot.
- `Models/StudyTracking.swift`: Foundational models and timer management logic for tracking study sessions.

## Data Sources
- `JSONs/mainListItems/sample1.json` contains sample list data for prototyping.

## Navigation Linkage
- Selecting a user within `SocialFeedView` pushes `StudyMemberDetailView` inside the same `NavigationStack`.
- The tab bar routes users to other feature root views (`FocusView`, `GroupsView`, `ModesView`) without additional cross-feature dependencies yet.

