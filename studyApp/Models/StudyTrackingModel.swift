//  StudyTrackingModel.swift
//  studyApp
//
//  Scaffolding for live study sessions and post-session analytics fields.

import Foundation
import Combine

// MARK: - Supporting Types

struct SessionLocation: Codable, Equatable {
    var description: String?
    var latitude: Double?
    var longitude: Double?
}

struct StudyBreak: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date

    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
}

struct FocusSnapshot: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    var value: Double
    var capturedAt: Date
}

/// Represents an individual study session, both while active and once completed.
struct StudySession: Identifiable, Codable {
    let id: UUID
    var subject: Subject?
    var subjectName: String?
    var startedAt: Date
    var endedAt: Date?
    var isPaused: Bool
    var lastResumedAt: Date
    var lastPausedAt: Date?
    var activeDuration: TimeInterval
    var totalBreakDuration: TimeInterval
    var breaks: [StudyBreak]
    var focusSnapshots: [FocusSnapshot]
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
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        isPaused: Bool = false,
        lastResumedAt: Date = Date(),
        lastPausedAt: Date? = nil,
        activeDuration: TimeInterval = 0,
        totalBreakDuration: TimeInterval = 0,
        breaks: [StudyBreak] = [],
        focusSnapshots: [FocusSnapshot] = [],
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
        self.activeDuration = activeDuration
        self.totalBreakDuration = totalBreakDuration
        self.breaks = breaks
        self.focusSnapshots = focusSnapshots
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
            return activeDuration
        } else {
            return activeDuration + Date().timeIntervalSince(lastResumedAt)
        }
    }
}

// MARK: - Session Store / Logic

final class StudyTrackingModel: ObservableObject {
    @Published private(set) var activeSession: StudySession?
    @Published private(set) var completedSessions: [StudySession] = []

    /// Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    private let breakThreshold: TimeInterval = 60 * 3 // 3 minutes to count as a break

    /// Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession(subject: Subject? = nil, subjectName: String? = nil) {
        let now = Date()
        activeSession = StudySession(
            subject: subject,
            subjectName: subjectName,
            startedAt: now,
            lastResumedAt: now
        )
    }

    /// Convenience for the UI start/stop button; routes to pause/resume depending on current state.
    func togglePause() {
        guard let session = activeSession else { return }
        session.isPaused ? resumeSession() : pauseSession()
    }

    /// Pause timing and accumulate active duration; call when the user taps Stop/Pause.
    func pauseSession() {
        guard var session = activeSession, !session.isPaused else { return }
        let now = Date()
        session.activeDuration += now.timeIntervalSince(session.lastResumedAt)
        session.isPaused = true
        session.lastPausedAt = now
        activeSession = session
    }

    /// Resume timing and log a break if the pause exceeded the break threshold; call when the user resumes.
    func resumeSession() {
        guard var session = activeSession, session.isPaused, let pausedAt = session.lastPausedAt else { return }
        let now = Date()
        let pausedDuration = now.timeIntervalSince(pausedAt)
        session.totalBreakDuration += pausedDuration

        if pausedDuration >= breakThreshold {
            session.breaks.append(StudyBreak(startedAt: pausedAt, endedAt: now))
        }

        session.isPaused = false
        session.lastResumedAt = now
        session.lastPausedAt = nil
        activeSession = session
    }

    /// Finalize the session, attach optional metadata (score, companions, location placeholder), and archive it.
    func endSession(score: Int? = nil, companions: [String] = [], locationDescription: String? = nil) {
        guard var session = activeSession else { return }
        let now = Date()

        if !session.isPaused {
            session.activeDuration += now.timeIntervalSince(session.lastResumedAt)
        }

        session.isPaused = false
        session.lastPausedAt = nil
        session.endedAt = now
        session.studyScore = score

        if !companions.isEmpty {
            session.companions = companions
        }

        if var existingLocation = session.location {
            if existingLocation.description == nil {
                existingLocation.description = locationDescription
            }
            session.location = existingLocation
        } else if locationDescription != nil {
            session.location = SessionLocation(description: locationDescription, latitude: nil, longitude: nil)
        }

        completedSessions.append(session)
        activeSession = nil
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        activeSession = nil
    }

    /// Capture a focus slider reading over time for later trend analysis; safe to call during an active session only.
    func logFocusIntensity(_ value: Double, at date: Date = Date()) {
        guard var session = activeSession else { return }
        session.focusSnapshots.append(FocusSnapshot(value: value, capturedAt: date))
        activeSession = session
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        guard var session = activeSession else { return }
        session.interruptionCount += 1
        activeSession = session
    }
}
