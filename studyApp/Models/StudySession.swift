//  StudySession.swift
//  studyApp
//
//  Data models for study sessions.

import Foundation

// MARK: - Supporting Types

struct SessionLocation: Codable, Equatable { //optional placeholder for future location tagging
    var description: String?
    var latitude: Double?
    var longitude: Double?
}

struct StudyBreak: Identifiable, Codable, Equatable { //records a single breakPeriod
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date

    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) } //computed property
}

/// Represents an individual study session, both while active and once completed.
struct StudySession: Identifiable, Codable {
    var id: UUID
    var subject: Subject?
    var subjectName: String?
    var startedAt: Date
    var endedAt: Date?
    var isPaused: Bool

    //could probably combine these two into one property which isn't tracked but computed and displayed on the focus screen
    var lastResumedAt: Date 
    var lastPausedAt: Date?

    var totalActiveDuration: TimeInterval
    var totalBreakDuration: TimeInterval
    var breaks: [StudyBreak]
    var companions: [String] // placeholder for other users in the session
    var location: SessionLocation?
    var studyScore: Int? // 0...10 rating at completion
    var notes: String?
    var interruptionCount: Int

    // Future analytics: screen time per app/category can be attached here once available.

    init(
        id: UUID = UUID(),
        subject: Subject? = nil,
        subjectName: String? = nil,
        startedAt: Date = Date.now,
        endedAt: Date? = nil,
        isPaused: Bool = false,
        lastResumedAt: Date = Date(),
        lastPausedAt: Date? = nil,
        activeDuration: TimeInterval = 0,
        totalBreakDuration: TimeInterval = 0,
        breaks: [StudyBreak] = [],
        companions: [String] = [],
        location: SessionLocation? = nil,
        studyScore: Int? = nil,
        notes: String? = nil,
        interruptionCount: Int = 0
    ) {
        self.id = id
        self.subject = subject
        self.subjectName = subjectName ?? subject?.name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isPaused = isPaused
        self.lastResumedAt = lastResumedAt
        self.lastPausedAt = lastPausedAt
        self.totalActiveDuration = activeDuration
        self.totalBreakDuration = totalBreakDuration
        self.breaks = breaks
        self.companions = companions
        self.location = location
        self.studyScore = studyScore
        self.notes = notes
        self.interruptionCount = interruptionCount
    }

    var totalElapsed: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    var runningActiveDuration: TimeInterval {
        if isPaused {
            return totalActiveDuration
        } else {
            return totalActiveDuration + Date().timeIntervalSince(lastResumedAt)
        }
    }
}
