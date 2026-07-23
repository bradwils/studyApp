# StudySession

## Overview
`StudySession` is a SwiftData model that captures a single study session, holding everything about it including breaks, sections, and light analytics.

## Properties
| Name | Type | Notes |
|------|------|-------|
| `id` | `UUID` | |
| `subject` | `Subject?` | `.nullify` relationship — deleting the subject doesn't delete the session |
| `subjectName` | `String?` | Denormalized copy, preserved if `subject` is later deleted |
| `startedAt` | `Date` | |
| `endedAt` | `Date?` | |
| `lastPausedAt` | `Date?` | |
| `breaks` | `[StudyBreak]?` | `.cascade` relationship |
| `sections` | `[StudySection]?` | `.cascade` relationship |
| `location` | `SessionLocation?` | `.cascade` relationship |
| `friends` | `[String]?` | Placeholder for other users in the session |
| `studyScore` | `Int?` | 0...10 rating at completion |
| `notes` | `String?` | |
| `interruptionCount` | `Int` | |
| `totalBreakDuration` | `TimeInterval?` | |

### Computed
- `totalDuration` — wall-clock duration from `startedAt` to `endedAt` (or now, if still active)
- `totalActiveDuration` — `totalDuration` minus the sum of all `breaks` durations

### Used Models
- [SessionLocation](SessionLocation.md)
- `StudyBreak`
- `StudySection`

## Initializers

### Primary
All parameters have defaults except none are strictly required — `subject` is optional here.
```swift
StudySession(
    id: UUID = UUID(),
    subject: Subject? = nil,
    subjectName: String? = nil,
    startedAt: Date = Date(),
    endedAt: Date? = nil,
    lastPausedAt: Date? = nil,
    totalBreakDuration: TimeInterval? = 0,
    breaks: [StudyBreak] = [],
    sections: [StudySection] = [],
    friends: [String]? = [],
    location: SessionLocation? = nil,
    studyScore: Int? = nil,
    notes: String? = nil,
    interruptionCount: Int = 0
)
```

### Convenience
Requires a real `subject` and `startedAt` — used when starting a session for a known subject.
```swift
StudySession(
    id: UUID = UUID(),
    subject: Subject,
    subjectName: String?,
    startedAt: Date,
    breaks: [StudyBreak] = [],
    sections: [StudySection] = [],
    friends: [String] = []
)
```

## SwiftData Relationship
- `subject`: `.nullify` — session survives if the subject is deleted
- `breaks`, `sections`, `location`: `.cascade` — owned by the session, deleted with it

## Used Flows
- `StudyTrackingViewModel` creates and mutates the active session through a full study session lifecycle (start → pause/resume → end).
