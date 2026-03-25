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

    var selectedSubjectDisplayName: String {
        selectedSubject?.name ?? "No subject"
    }

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

    /// Convenience for the UI start/pause button.
    func toggleSessionProgress() {
        guard activeSession != nil else {
            startSession(subject: selectedSubject, subjectName: selectedSubject?.name)
            return
        }

        togglePause()
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
        refreshDerivedState()
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
        startTickerIfNeeded()
        refreshDerivedState()
    }

    /// Finalize the active session and archive it.
    func endCurrentSession(score: Int? = nil, companions: [String] = [], locationDescription: String? = nil) {
        endSession(score: score, companions: companions, locationDescription: locationDescription)
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
        stopTicker()
        refreshDerivedState()
    }

    /// Abort an active session without persisting; use for user-initiated cancels.
    func cancelActiveSession() {
        activeSession = nil
        stopTicker()
        refreshDerivedState()
    }

    /// Increment an interruption counter (e.g., notifications/away events); can be wired to external signals later.
    func addInterruption() {
        guard var session = activeSession else { return }
        session.interruptionCount += 1
        activeSession = session
        refreshDerivedState()
    }

    /// Update the subject selection for the next session (only allowed when no session is active).
    func updateSubjectSelection(_ subject: Subject?) {
        guard activeSession == nil else { return }
        selectedSubject = subject
        refreshDerivedState()
    }

    func hasAlreadyStudiedToday() -> Bool {
        shouldShowTodaySummary
    }

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

    private static func formatHoursMinutesSeconds(from timeInterval: TimeInterval) -> String {
        hmsFormatter.string(from: max(timeInterval, 0)) ?? "00:00:00"
    }

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
