# StudySession

## Overview
StudySession is a SwiftData Model that captures a single study session from the user, which holds all of the information that the user wants about the session, including some analytics. 



## Properties
- SwiftData Model

### Used Structs
- SessionLocation
- StudyBreak





## Initializing
### Primary
- Nil can be passed for most values except for:
    - subject: Subject
    - startedAt: Date
```swift
    StudySession(
        id: UUID = UUID(),
        subject: Subject,
        subjectName: String?,
        startedAt: Date,
        endedAt: Date?,
        lastPausedAt: Date?,
        activeDuration: TimeInterval = 0,
        totalBreakDuration: TimeInterval = 0,
        breaks: [StudyBreak]?,
        friends: [String] = [], //TODO later
        location: SessionLocation?,
        studyScore: Int?,
        notes: String?,
        interruptionCount: Int?
        )
```

```swift
Initialise without any values
```


### Background
### Convinience

## SwiftData Relationship



## Used Flows


