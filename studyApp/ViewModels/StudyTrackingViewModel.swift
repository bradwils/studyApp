//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Foundation
import Combine

/// Manages the study timer lifecycle, break accounting, and derived labels that `StudyTrackingView` consumes.
///
/// The viewmodel owns the active/completed session arrays, formats readable totals, and exposes the start/pause/end helpers wired directly to the buttons in `StudyTrackingView`.
final class StudyTrackingViewModel: ObservableObject {
    @Published private(set) var activeSession: StudySession?
    @Published private(set) var completedSessions: [StudySession] = []
    @Published var selectedSubject: Subject?

    @Published var focusSliderValue: Double = 0
    @Published var sliderDraggableElementWidth: CGFloat = 90
    @Published var sliderDraggableElementHeight: CGFloat = 60
    @Published var onlineFriendCount: Int = 0
    @Published var isLeaderboardPresented: Bool = false

    @Published private(set) var timerInProgress: Bool = false
    @Published private(set) var currentStudySessionInProgress: Bool = false
    @Published private(set) var sessionDurationText: String = "00:00"
    @Published private(set) var totalStudyDurationText: String = "00:00:00"
    @Published private(set) var shouldShowTodaySummary: Bool = false
    @Published private(set) var breakMetricValueText: String = "00:00:00"
    @Published private(set) var breakMetricTitleText: String = "Break Length"

    /// Minimum paused duration that counts as a break when resuming; tweak for different break heuristics.
    private let breakThreshold: TimeInterval = 60 * 3
    private var sessionTicker: AnyCancellable?
    private let calendar = Calendar.current

    init() {
        refreshDerivedState()
    }

    /// Display label used by the UI to describe the currently queued subject.
    var selectedSubjectDisplayName: String {
        selectedSubject?.name ?? "No subject"
    }

    /// Establishes a default subject when the view first loads and recalculates derived labels.
    ///
    /// Called by `StudyTrackingView` as soon as the user profile subjects arrive or change.
    func configureSubjects(_ subjects: [Subject]) {
        if selectedSubject == nil {
            selectedSubject = subjects.first
        }
        refreshDerivedState()
    }

    /// Start a fresh session (count-up) for an optional subject; discards any in-progress session.
    func startSession(subject: Subject? = nil, subjectName: String? = nil) {
        let now = Date()
        activeSession = StudySession(
            subject: subject,
            subjectName: subjectName,
            startedAt: now,
            lastResumedAt: now
        )
        startTickerIfNeeded()
        refreshDerivedState()
    }

    /// Stops, starts, or resumes the timer depending on whether a session already exists.
    ///
    /// Bound to the round primary button inside `StudyTrackingView` so taps naturally start/resume/pause.
    func toggleSessionProgress() {
        guard activeSession != nil else {
            startSession(subject: selectedSubject, subjectName: selectedSubject?.name)
            return
        }

        togglePause()
    }

    /// Switches between pause/resume while leaving the underlying session intact.
    ///
    /// Used as a helper by the UI layer to keep `toggleSessionProgress()` concise.
    func togglePause() {
        guard let session = activeSession else { return }
        session.isPaused ? resumeSession() : pauseSession()
    }

    /// Pause timing and accumulate active duration; call when the user taps Stop/Pause.
    /// Accumulates the active duration before setting `isPaused` so the pause button honors elapsed time.
    ///
    /// Triggered from `toggleSessionProgress()` when the timer is running.
    func pauseSession() {
        guard var session = activeSession, !session.isPaused else { return }
        let now = Date()
        session.totalActiveDuration += now.timeIntervalSince(session.lastResumedAt)
        session.isPaused = true
        session.lastPausedAt = now
        activeSession = session
        refreshDerivedState()
    }

    /// Resumes timing and optionally logs a break if the pause exceeded `breakThreshold`.
    ///
    /// Called from `toggleSessionProgress()` when the user taps the same button while paused.
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
        startTickerIfNeeded()
        refreshDerivedState()
    }

    /// Finalize the active session and archive it.
    /// Ends the current session with optional metadata so the view can call it from the End button.
    func endCurrentSession(score: Int? = nil, companions: [String] = [], locationDescription: String? = nil) {
        endSession(score: score, companions: companions, locationDescription: locationDescription)
    }

    /// Finalizes the passed-in session, persists companion/location details, archives it, and clears the timer state.
    ///
    /// `StudyTrackingView` invokes this when the End button is visible while a session is active.
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
        stopTicker()
        refreshDerivedState()
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        activeSession = nil
        stopTicker()
        refreshDerivedState()
    }

    /// Increments the interruption counter so notifications or manual signals can track distractions.
    func addInterruption() {
        guard var session = activeSession else { return }
        session.interruptionCount += 1
        activeSession = session
        refreshDerivedState()
    }

    /// Updates the queued subject only when no session is running (the picker is disabled while a session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        guard activeSession == nil else { return }
        selectedSubject = subject
        refreshDerivedState()
    }

    /// Convenience exposed to `StudyTrackingView` so the summary row only shows after study time exists.
    func hasAlreadyStudiedToday() -> Bool {
        shouldShowTodaySummary
    }

    /// Syncs all derived published strings (timer text, break info, totals) whenever the session timeline changes.
    ///
    /// Runs after every state mutation and every second while the ticker fires so the UI labels remain accurate.
    private func refreshDerivedState(referenceDate: Date = Date()) {
        currentStudySessionInProgress = activeSession != nil
        timerInProgress = activeSession != nil && !(activeSession?.isPaused ?? true)

        let todayDuration = totalStudyDurationToday(referenceDate: referenceDate)
        totalStudyDurationText = Self.formatHoursMinutesSeconds(from: todayDuration)
        shouldShowTodaySummary = todayDuration > 0

        if let session = activeSession {
            sessionDurationText = Self.formatMinutesSeconds(from: session.runningActiveDuration)

            if session.isPaused {
                let pauseDuration = referenceDate.timeIntervalSince(session.lastPausedAt ?? referenceDate)
                breakMetricValueText = Self.formatHoursMinutesSeconds(from: pauseDuration)
                breakMetricTitleText = "Break Length"
            } else {
                let sinceLastBreak = referenceDate.timeIntervalSince(session.lastResumedAt)
                breakMetricValueText = Self.formatHoursMinutesSeconds(from: sinceLastBreak)
                breakMetricTitleText = "since last break"
            }
        } else {
            sessionDurationText = "00:00"
            breakMetricValueText = "00:00:00"
            breakMetricTitleText = "Break Length"
        }
    }

    /// Sums today's completed sessions plus the running session duration (when it started today) for the total badge.
    private func totalStudyDurationToday(referenceDate: Date) -> TimeInterval {
        let completedDuration = completedSessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: referenceDate) }
            .reduce(0) { $0 + $1.totalActiveDuration }

        let activeDuration: TimeInterval
        if let session = activeSession, calendar.isDate(session.startedAt, inSameDayAs: referenceDate) {
            activeDuration = session.runningActiveDuration
        } else {
            activeDuration = 0
        }

        return completedDuration + activeDuration
    }

    /// Creates the 1 Hz timer that keeps the published strings in sync while a session is running.
    private func startTickerIfNeeded() {
        guard sessionTicker == nil else { return }

        sessionTicker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDerivedState()
            }
    }

    private func stopTicker() {
        sessionTicker?.cancel()
        sessionTicker = nil
    }

    /// Formats a duration as `hh:mm:ss` for the daily totals and break metrics.
    private static func formatHoursMinutesSeconds(from timeInterval: TimeInterval) -> String {
        hmsFormatter.string(from: max(timeInterval, 0)) ?? "00:00:00"
    }

    /// Formats a duration as `mm:ss` for the live running session text.
    private static func formatMinutesSeconds(from timeInterval: TimeInterval) -> String {
        msFormatter.string(from: max(timeInterval, 0)) ?? "00:00"
    }

    private static let hmsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()

    private static let msFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
}
