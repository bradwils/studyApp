//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Foundation
import Combine
import SwiftData
import os

// MARK: - State Overview
// Three layers of state are touched during a session lifecycle:
//
// VM (self)
//   activeSession       — the live StudySession being built; nil when idle
//   completedSessions   — archive of finished sessions
//   selectedSubject     — subject for the next/current session
//   sessionIsRunning    — mirrors stopwatch + session state for UI binding
//   ssw    — optional Stopwatch tracking elapsed time
//
// Stopwatch (ssw)
//   startedAt           — wall-clock anchor; re-anchored on resume
//   stopwatchIsRunning  — true while actively counting
//   lastPausedAt        — set on pause; used to compute break length on resume
//   previousBreaksLength— accumulated break time subtracted from wall time
//   totalStudyingTime   — computed: wall elapsed − previousBreaksLength
//
// StudySession (activeSession)
//   startedAt / endedAt — session boundaries
//   lastPausedAt        — persisted pause timestamp (mirrors stopwatch.lastPausedAt)
//   totalBreakDuration  — accumulated break time written on end
//   breaks              — [StudyBreak] appended when pause > breakThreshold
//   interruptionCount   — incremented by addInterruption()
//   studyScore / notes / friends / location — written at endSession()

@Observable
final class StudyTrackingViewModel {
    let logger = Logger(subsystem: "com.studyApp", category: "StudyTrackingViewModel")

    var ssw: Stopwatch?
    var studyBreaks: [StudyBreak]
    var studySections: [StudySection]
    var activeSession: StudySession?
    var selectedSubject: Subject?
    var sessionIsRunning: Bool

    init() {
        ssw = Stopwatch(startNow: false)
        studyBreaks = []
        studySections = []
        sessionIsRunning = false
    }

    var totalStudyingTime: TimeInterval {
        studySections.reduce(0) { $0 + $1.duration }
    }

    var totalBreakTime: TimeInterval {
        studyBreaks.reduce(0) { $0 + $1.duration }
    }

    // Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    private let breakThreshold: TimeInterval = 60 * 3 // 3 minutes to count as a break



    //MARK: VM-Stopwatch Functions


    // Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession() {
        guard activeSession == nil else {
            logger.warning("Failed to start session; there is already an active session.")
            return
        }

        ssw = Stopwatch(startNow: true)
        studyBreaks = []
        studySections = []

        activeSession = StudySession(subject: selectedSubject, subjectName: selectedSubject?.name, startedAt: Date.now)
        sessionIsRunning = true
    }

    /// Convenience for the UI start/stop button; routes to pause/resume depending on current state.
    func togglePause() {
        guard activeSession != nil else { return }
        sessionIsRunning ? pauseSession() : resumeSession()
    }

    /// Pause timing; call when the user taps Pause.
    func pauseSession() {
        guard activeSession != nil, sessionIsRunning else { return }
        ssw!.startBreak()
        activeSession?.lastPausedAt = ssw!.lastPausedAt
        sessionIsRunning = false
    }

    /// Resume timing and log a break if the pause exceeded the break threshold.
    func resumeSession() {
        guard let pausedAt = ssw!.lastPausedAt, !sessionIsRunning else { return }
        let now = Date()
        let pausedDuration = now.timeIntervalSince(pausedAt)
        if pausedDuration >= breakThreshold {
            studyBreaks.append(StudyBreak(startedAt: pausedAt, endedAt: now))
        }
        ssw!.resume()
        activeSession?.lastPausedAt = nil
        sessionIsRunning = true
    }

    /// Finalize the session and attach optional metadata.
    func endSession(score: Int? = nil, companions: [String] = [], locationDescription: String? = nil) {
        guard let session = activeSession else { return }
        let now = Date.now
        session.endedAt = now
        session.studyScore = score
        session.breaks = studyBreaks
        session.totalBreakDuration = totalBreakTime
        if !companions.isEmpty { session.friends = companions }
        if let locationDescription {
            if session.location != nil {
                if session.location?.locationDescription == nil {
                    session.location?.locationDescription = locationDescription
                }
            } else {
                session.location = SessionLocation(locationDescription: locationDescription, locationLabel: "")
            }
        }
        ssw!.end()
        sessionIsRunning = false
        activeSession = nil
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        activeSession = nil
        ssw = nil
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        activeSession?.interruptionCount += 1
    }

    /// Update the subject selection for the next session (only allowed when no session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        guard activeSession == nil else { return }
        selectedSubject = subject
    }

    public func hasAlreadyStudiedToday() -> Bool {
        //todo
        return false; //stub placeholder
    }
}
