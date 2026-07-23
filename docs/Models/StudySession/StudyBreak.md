# Data Items

```startedAt: Date``` - Date that captures the start of the study break

```endedAt: Date``` - Date that captures the end of the study break, can be added after the study break has ended.

```duration: TimeInterval``` - Total duration of the study break, automatically computed based on


## Purpose

- StudyBreaks are collected within a StudySession to track breaks taken. The most recently appended StudyBreak will be the most recent one, and we assume this logic when we're updating a StudySession.

```swift

var breaks: [StudyBreak] = []

func pause() {
    //Create a new study break and assign Date.now as the start time
}

func pause()
    //get the last element of breaks and assign Date.now as the end time
```
