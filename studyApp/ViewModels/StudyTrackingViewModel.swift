//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Combine
import Foundation
import SwiftData
import os

//TODO: Check over changes, particuarly for the PureFocusTimer.

@Observable
final class StudyTrackingViewModel {
    let studyTrackingLogger = Logger(subsystem: "com.studyApp", category: "studyTracking")
	
	let pureFocusLogger = Logger(subsystem: "com.studyApp", category: "pureFocus")
    
	

    var ssw: Stopwatch?
    var studyBreaks: [StudyBreak]
    var studySections: [StudySection]
    var activeSession: StudySession? {
        didSet {
            studyTrackingLogger.log("activeSession set to \(String(describing: self.activeSession))")
        }
    }
	
    var selectedSubject: Subject?
	
	private let breakThreshold: TimeInterval = 60 * 3 // 3 minutes to count as a break
	
	
	//MARK: PureFocus vars
	
	var activePureFocusSession: pureFocusSession? = nil
	
	struct pureFocusSession {

		///Marks the starting Date of the pureFocusSesssion
		let pureFocusStartTime: Date

		///Marks the goal Date of the pureFocusSession; cleared independently of the
		///session by closeSession() so the clock can keep running with no target.
		var pureFocusGoal: Date

		///To initialise, pass the starting time & the TimeInterval of the goal.
		init(startTime: Date, goal: TimeInterval) {
			self.pureFocusStartTime = startTime
			self.pureFocusGoal = Date.now.addingTimeInterval(goal)
		}

	}

	/// marks how we've been focused for in our session
	var pureFocusDuration: TimeInterval? {
		guard let startTime = self.activePureFocusSession?.pureFocusStartTime else { return nil }
		return Date.now.timeIntervalSince(startTime)
	}

	var isFocusSessionRunning: Bool { return activePureFocusSession != nil }

	
	///Controlled by the lock button
    var focusLockEnabled: Bool = false

    var minHours: Int = 0
    var maxHours: Int = 8
    var minMinutes: Int = 0
    var maxMinutes: Int = 59

	//MARK: Enums
	
	enum SessionState: Equatable {
		
		case noSession
		case sessionRunning(Date) //Date contains the adjustedStartTimeForAnchor
		case sessionPaused(Date)  //Date contains lastPausedAt
		
		
	}
	
	//MARK: Initialisers

    init() {
        studyBreaks = []
        studySections = []
    }

	//MARK: Computed Vars
	
    var totalStudyingTime: TimeInterval {
        studySections.reduce(0) { $0 + $1.duration }
    }

    var totalBreakTime: TimeInterval {
        studyBreaks.reduce(0) { $0 + $1.duration }
    }

    // Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    
	
	var sessionIsRunning: Bool {
		activeSession != nil
	}
    

    var currentSessionState: SessionState {
        guard let isRunning = ssw?.stopwatchIsRunning else {
            studyTrackingLogger.log("logging noSession")
            return .noSession
        }
		
        if isRunning == true { //give the anchor Date
            studyTrackingLogger.log("isRunning == true")
            return .sessionRunning(ssw!.adjustedStartTimeForAnchor!)
        }
		
        studyTrackingLogger.log("all else")
        return .sessionPaused(ssw!.lastPausedAt!) //give the Date paused at.
    }

    var elapsed: TimeInterval {
        ssw?.totalRunningTime ?? 0
    }
	

    var pureFocusSessionProgress: CGFloat? {
		guard let session = self.activePureFocusSession else { return nil }
				
		let goal =  session.pureFocusGoal
				
		let target = goal.timeIntervalSince(session.pureFocusStartTime)
				
		guard target > 0 else { return nil }
		let elapsedFraction = Date.now.timeIntervalSince(session.pureFocusStartTime) / target
        return CGFloat(min(max(elapsedFraction, 0), 1))
    }

    var timerIsRunning: Bool {
        ssw?.stopwatchIsRunning ?? false
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
	//MARK: View-Functions


    // Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession(ctx: ModelContext) {
        let now = Date()
        studyTrackingLogger.log("startSession() called")
        guard activeSession == nil else {
            studyTrackingLogger.warning("Failed to start session; there is already an active session.")
            return
        }

        ssw = Stopwatch()
        studyBreaks = []
        studySections = []

        activeSession = StudySession(subject: selectedSubject, subjectName: selectedSubject?.name, startedAt: now)
        studyTrackingLogger.log("Session Started")
        
        ctx.insert(activeSession!)
        try? ctx.save()
    }

    /// Convenience for the UI start/stop button; routes to pause/resume depending on current state.
    func togglePause() {
        studyTrackingLogger.log("togglePause() called")
        guard activeSession != nil else { return }
        (ssw?.stopwatchIsRunning ?? false) ? pauseSession() : resumeSession()
    }

    /// Pause timing; call when the user taps Pause.
    // - We need to:
    //      - End the study Break
    //      - Resume stopwatch & update resume timing
    func pauseSession() {
        let now = Date()
        studyTrackingLogger.log("pauseSession() called")
        guard activeSession != nil, ssw?.stopwatchIsRunning ?? false else { return }
        ssw!.startBreak()
        activeSession?.lastPausedAt = ssw!.lastPausedAt


    }

    /// Resume timing and log a break if the pause exceeded the break threshold.
    func resumeSession() {
        studyTrackingLogger.log("resumeSession() called")
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
    func endSession(context: ModelContext) {
        studyTrackingLogger.log("endSession() called")
        guard let session = activeSession else { return }
        let now = Date()
        session.endedAt = now
        session.breaks = studyBreaks
        session.sections = studySections
        session.totalBreakDuration = totalBreakTime

        ssw?.end()
        ssw = nil
        activeSession = nil
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession(ctx: ModelContext) {
        studyTrackingLogger.log("current session cancelled")
        ctx.delete(activeSession!)
        try? ctx.save()
        activeSession = nil
        ssw = nil
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        studyTrackingLogger.log("addInterruption() called")
        activeSession?.interruptionCount += 1
    }

    /// Update the subject selection for the next session (only allowed when no session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        studyTrackingLogger.log("updateSubjectSelection(_:) called with subject: \(String(describing: subject))")
        guard activeSession == nil else { return }
        selectedSubject = subject
    }

    func startPureFocusSession(_ duration: TimeInterval) {
		let now = Date.now
		activePureFocusSession = pureFocusSession(startTime: now, goal: duration)
    }

    // Non-destructive by design: the session and stopwatch keep running, only the target is forgotten.
    func closePureFocusSession() {
		activePureFocusSession = nil
    }

    public func hasAlreadyStudiedToday() -> Bool {

        return false; //stub placeholder
    }
    
    
    public func logAllVars() {
        studyTrackingLogger.log("""
        
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
