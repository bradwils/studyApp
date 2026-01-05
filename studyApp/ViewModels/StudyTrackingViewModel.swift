//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Foundation
import Combine

final class StudyTrackingViewModel: ObservableObject {
    @Published private(set) var activeSession: StudySession?
    @Published private(set) var completedSessions: [StudySession] = []
    @Published var selectedSubject: Subject?

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
        session.totalActiveDuration += now.timeIntervalSince(session.lastResumedAt)
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
            session.totalActiveDuration += now.timeIntervalSince(session.lastResumedAt)
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

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        guard var session = activeSession else { return }
        session.interruptionCount += 1
        activeSession = session
    }

    /// Update the subject selection for the next session (only allowed when no session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        guard activeSession == nil else { return }
        selectedSubject = subject
    }
}
