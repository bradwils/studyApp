# StudyBreak

## Overview
StudyBreak is a SwiftData model that records a single break period within a study session — a span of time the user stepped away. A `StudySession` holds zero or more breaks, and their combined duration is subtracted from the session's total time to produce active study time.

## Properties
| Name | Type | Description |
|------|------|-------------|
| `startedAt` | `Date` | When the break began |
| `endedAt` | `Date?` | When the break ended; `nil` while the break is still in progress |
| `duration` | `TimeInterval` | Computed. `endedAt - startedAt`, or `0` if the break hasn't ended yet |

## Initializers

### Designated Initializer
```swift
init(startedAt: Date, endedAt: Date)
```
Creates a completed break with both endpoints known.

### Convenience Initializer
```swift
init()
```
Starts an open-ended break at `Date.now` with no `endedAt` — used when a break begins and its end time isn't known yet.

## SwiftData Relationship
- **Owned by**: `StudySession.breaks` (one-to-many)
- Registered directly in the app's `modelContainer` (see [StudyAppApp.swift](../../../studyApp/App/StudyAppApp.swift))

## Used Flows
- `StudyTrackingViewModel.resumeSession()` appends a `StudyBreak` when a pause exceeds the 3-minute break threshold. See [StudySession.md](StudySession.md#used-flows) for the full session lifecycle and a note on a current mismatch between this view model and the persisted model shape.
