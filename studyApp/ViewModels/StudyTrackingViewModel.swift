//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Foundation
import Combine
import SwiftData

@Observable
final class StudyTrackingViewModel {
    private(set) var activeSession: StudySession?
    private(set) var completedSessions: [StudySession] = []
    var selectedSubject: Subject?

    /// Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    private let breakThreshold: TimeInterval = 60 * 3 // 3 minutes to count as a break

    /// Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession(subject: Subject? = nil, subjectName: String? = nil) {
        let now = Date()
        activeSession = StudySession(
            subject: subject,
            subjectName: subjectName,
            startedAt: now,
            endedAt: nil,
            lastPausedAt: nil,
            activeDuration: 0,
            totalBreakDuration: nil,
            breaks: [],
            location: nil,
            studyScore: nil,
            notes: nil,
            interruptionCount: 0
        )
    }

    /// Convenience for the UI start/stop button; routes to pause/resume depending on current state.
    func togglePause() {
        guard let session = activeSession else { return }
        let isPaused = session.endedAt != nil
        isPaused ? resumeSession() : pauseSession()
    }

    /// Pause timing and accumulate active duration; call when the user taps Stop/Pause.
    func pauseSession() {
        guard var session = activeSession, session.endedAt == nil else { return }
        let now = Date()
        session.lastPausedAt = now
        activeSession = session
    }

    /// Resume timing and log a break if the pause exceeded the break threshold; call when the user resumes.
    func resumeSession() {
        guard var session = activeSession, let pausedAt = session.lastPausedAt else { return }
        let now = Date()
        let pausedDuration = now.timeIntervalSince(pausedAt)
        session.totalBreakDuration = (session.totalBreakDuration ?? 0) + pausedDuration

        if pausedDuration >= breakThreshold {
            var breaks = session.breaks ?? []
            breaks.append(StudyBreak(startedAt: pausedAt, endedAt: now))
            session.breaks = breaks
        }

        session.lastPausedAt = nil
        activeSession = session
    }

    /// Finalize the session, attach optional metadata (score, companions, location placeholder), and archive it.
    func endSession(score: Int? = nil, companions: [String] = [], locationDescription: String? = nil, context: ModelContext) {
        guard var session = activeSession else { return }
        let now = Date()

        session.endedAt = now
        session.studyScore = score

        if !companions.isEmpty {
            session.friends = companions
        }

        if var existingLocation = session.location {
            if existingLocation.locationDescription == nil {
                existingLocation.locationDescription = locationDescription
            }
            session.location = existingLocation
        } else if locationDescription != nil {
            session.location = SessionLocation(locationDescription: locationDescription, latitude: nil, longitude: nil, locationLabel: "")
        }

        context.insert(session)
        try? context.save()
        completedSessions.append(session)
        activeSession = nil
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        activeSession = nil
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        guard var session = activeSession else { return }
        session.interruptionCount += 1
        activeSession = session
    }

    /// Update the subject selection and update active session's subject if one is in progress.
    func updateSubjectSelection(_ subject: Subject?) {
        selectedSubject = subject
        if var session = activeSession {
            session.subject = subject
            activeSession = session
        }
    }

    public func hasAlreadyStudiedToday() -> Bool {
        //todo
        return false; //stub placeholder
    }
}
