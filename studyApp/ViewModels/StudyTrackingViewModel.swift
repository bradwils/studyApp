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
//   sessionIsRunning    — true if there's an active stopwatch (running or paused)
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

    // True if there's an active stopwatch (running or paused); false when idle.
    var sessionIsRunning: Bool {
        ssw != nil
    }

    init() {
        studyBreaks = []
        studySections = []
    }

    var totalStudyingTime: TimeInterval {
        studySections.reduce(0) { $0 + $1.duration }
    }

    var totalBreakTime: TimeInterval {
        studyBreaks.reduce(0) { $0 + $1.duration }
    }

    // Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    private let breakThreshold: TimeInterval = 60 * 3 // 3 minutes to count as a break
    
    
    //MARK: View-Functions
    
    enum SessionState {
        
        case noSession
        case sessionRunning(Date) //Date contains the adjustedStartTimeForAnchor
        case sessionPaused(Date)  //Date contains lastPausedAt
        
    }
    
    var currentSessionState: SessionState {
        guard let isRunning = ssw?.stopwatchIsRunning else {
            logger.log("logging noSession")
            return .noSession
        }
        if isRunning == true { //give the anchor Date
            logger.log("isRunning == true")
            return .sessionRunning(ssw!.adjustedStartTimeForAnchor!)
        }
        logger.log("all else")
        return .sessionPaused(ssw!.lastPausedAt!) //give the Date paused at.
    }
    
        
    
    

    // TODO(human): Add a single computed var (e.g. `currentTimerAnchor`) that resolves
    // to whichever timer is currently authoritative: nothing running, the break timer
    // (ssw?.lastPausedAt), or the study timer (ssw?.adjustedStartTimeForAnchor). Derive it
    // from `ssw?.stopwatchIsRunning` and whether `ssw` exists at all. StudyTrackingView's
    // timerAndControlsSection should then switch on this single value instead of branching
    // on ssw state directly.
    //
    // Note: the daily-total-vs-weekly-total display (driven by hasAlreadyStudiedToday())
    // is a separate, not-yet-addressed concern — out of scope for this var.

    //MARK: VM-Stopwatch Functions


    // Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession() {
        let now = Date()
        logger.log("startSession() called")
        guard activeSession == nil else {
            logger.warning("Failed to start session; there is already an active session.")
            return
        }

        ssw = Stopwatch()
        studyBreaks = []
        studySections = []

        activeSession = StudySession(subject: selectedSubject, subjectName: selectedSubject?.name, startedAt: now)
        logger.log("Session Started")
    }

    /// Convenience for the UI start/stop button; routes to pause/resume depending on current state.
    func togglePause() {
        logger.log("togglePause() called")
        guard activeSession != nil else { return }
        (ssw?.stopwatchIsRunning ?? false) ? pauseSession() : resumeSession()
    }

    /// Pause timing; call when the user taps Pause.
    // - We need to:
    //      - End the study Break
    //      - Resume stopwatch & update resume timing
    func pauseSession() {
        let now = Date()
        logger.log("pauseSession() called")
        studyBreaks.append(StudyBreak(startedAt: now)) //append a new StudyBreak
        guard activeSession != nil, ssw?.stopwatchIsRunning ?? false else { return }
        ssw!.startBreak()
        activeSession?.lastPausedAt = ssw!.lastPausedAt


    }

    /// Resume timing and log a break if the pause exceeded the break threshold.
    func resumeSession() {
        logger.log("resumeSession() called")
        guard let pausedAt = ssw!.lastPausedAt, !(ssw?.stopwatchIsRunning ?? false) else { return }
        let now = Date()
        let pausedDuration = now.timeIntervalSince(pausedAt)
//        if pausedDuration >= breakThreshold {
        if pausedDuration >= 0 {

            studyBreaks.append(StudyBreak(startedAt: pausedAt, endedAt: now))
        } else {
            //update normal time to disregard break
        }
        ssw!.endBreak()
        activeSession?.lastPausedAt = nil
        
        studyBreaks.last?.endedAt = now
        
    }

    //Finalize section and assign all values over to the study session to 'finish' it
    func endSession(context: ModelContext, score: Int? = nil) {
        logger.log("endSession() called")
        guard let session = activeSession else { return }
        let now = Date()
        session.endedAt = now
        session.studyScore = score
        session.breaks = studyBreaks
        session.sections = studySections
        session.totalBreakDuration = totalBreakTime

        context.insert(session)
        try? context.save()

        ssw?.end()
        ssw = nil
        activeSession = nil
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        logger.log("cancelActiveSession() called")
        activeSession = nil
        ssw = nil
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        logger.log("addInterruption() called")
        activeSession?.interruptionCount += 1
    }

    /// Update the subject selection for the next session (only allowed when no session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        logger.log("updateSubjectSelection(_:) called with subject: \(String(describing: subject))")
        guard activeSession == nil else { return }
        selectedSubject = subject
    }

    public func hasAlreadyStudiedToday() -> Bool {
        logger.log("hasAlreadyStudiedToday() called")
        //todo
        return false; //stub placeholder
    }
    
    
    public func logAllVars() {
        logger.log("""
        
        --- StudyTrackingViewModel State ---
        sessionIsRunning:  \(self.sessionIsRunning)
        totalStudyingTime: \(self.totalStudyingTime)
        totalBreakTime:    \(self.totalBreakTime)
        activeSession:     \(String(describing: self.activeSession))
        selectedSubject:   \(self.selectedSubject != nil ? String(describing: self.selectedSubject!.name) : "nil")
        ssw (Stopwatch):   \(String(describing: self.ssw))
        studyBreaks:       \(self.studyBreaks.count) break(s)
        studySections:     \(self.studySections.count) section(s)
        breakThreshold:    \(self.breakThreshold)
        ------------------------------------
        """)
    }
    
    
}
