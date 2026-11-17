//  FocusLabSession.swift
//  studyApp
//
//  DEV ONLY — cosmetic stand-in for StudyTrackingViewModel. Focus Design Lab screens
//  drive this instead of the real view model, so nothing they do reaches SwiftData.

import Foundation

@Observable
final class FocusLabSession {

    enum Phase: Equatable {
        case idle
        case running
        case paused
    }

    struct LabSubject: Identifiable, Hashable {
        let code: String
        let name: String
        var id: String { code }
    }

    struct LabFriend: Identifiable, Hashable {
        let name: String
        var id: String { name }
    }

    struct Segment: Identifiable, Hashable {
        enum Kind: Hashable {
            case study
            case rest
        }

        let id: Int
        let kind: Kind
        var start: Date
        /// nil while the segment is still open.
        var end: Date?
    }

    static let sampleSubjects: [LabSubject] = [
        LabSubject(code: "PSYC2001", name: "Cognitive Psychology"),
        LabSubject(code: "PSYC2012", name: "Research Methods"),
        LabSubject(code: "STAT2170", name: "Applied Statistics"),
        LabSubject(code: "PHIL1037", name: "Critical Thinking")
    ]

    static let sampleFriends: [LabFriend] = [
        LabFriend(name: "Mia"),
        LabFriend(name: "Arjun"),
        LabFriend(name: "Tess")
    ]

    static let focusPresets: [TimeInterval] = [15 * 60, 25 * 60, 45 * 60, 60 * 60, 90 * 60]

    let subjects = FocusLabSession.sampleSubjects
    let friends = FocusLabSession.sampleFriends
    let studiedEarlierToday: TimeInterval = 2 * 3600 + 14 * 60

    var selectedSubject: LabSubject = FocusLabSession.sampleSubjects[0]
    var focusDuration: TimeInterval = 25 * 60
    var isLocked = false

    private(set) var phase: Phase = .idle
    private(set) var startedAt: Date?
    /// Session start pushed forward by every finished break, so `now - studyAnchor` is net study time.
    private(set) var studyAnchor: Date?
    private(set) var pausedAt: Date?
    private(set) var breakCount = 0
    private(set) var finishedBreakTime: TimeInterval = 0
    private(set) var focusStart: Date?
    private(set) var focusGoal: Date?
    private(set) var segments: [Segment] = []
    private(set) var lastCompletedLength: TimeInterval?

    // MARK: - State

    var hasSession: Bool { phase != .idle }
    var isPaused: Bool { phase == .paused }
    var hasFocusBlock: Bool { focusGoal != nil }

    // MARK: - Time

    /// Study and focus time stand still during a break, so both are measured up to the pause.
    private func studyClock(at date: Date) -> Date {
        guard let pausedAt else { return date }
        return min(pausedAt, date)
    }

    func studyElapsed(at date: Date = .now) -> TimeInterval {
        guard let studyAnchor else { return 0 }
        return max(0, studyClock(at: date).timeIntervalSince(studyAnchor))
    }

    func currentBreakElapsed(at date: Date = .now) -> TimeInterval {
        guard let pausedAt else { return 0 }
        return max(0, date.timeIntervalSince(pausedAt))
    }

    func breakTime(at date: Date = .now) -> TimeInterval {
        finishedBreakTime + currentBreakElapsed(at: date)
    }

    func todayTotal(at date: Date = .now) -> TimeInterval {
        studiedEarlierToday + studyElapsed(at: date)
    }

    /// 0...1 through the focus block, nil when there isn't one.
    func focusProgress(at date: Date = .now) -> Double? {
        guard let focusStart, let focusGoal else { return nil }
        let length = focusGoal.timeIntervalSince(focusStart)
        guard length > 0 else { return nil }
        let done = studyClock(at: date).timeIntervalSince(focusStart)
        return min(max(done / length, 0), 1)
    }

    func focusRemaining(at date: Date = .now) -> TimeInterval? {
        guard let focusGoal else { return nil }
        return max(0, focusGoal.timeIntervalSince(studyClock(at: date)))
    }

    func isFocusComplete(at date: Date = .now) -> Bool {
        guard let remaining = focusRemaining(at: date) else { return false }
        return remaining <= 0
    }

    /// What the timer shows: break time while paused, time left while a focus block runs, study time otherwise.
    func clockSeconds(at date: Date = .now) -> TimeInterval? {
        if isPaused { return currentBreakElapsed(at: date) }
        if hasFocusBlock { return focusRemaining(at: date) }
        return hasSession ? studyElapsed(at: date) : nil
    }

    /// Whole-second ticks line up with this date, so the clock redraws exactly as its digits change.
    var clockTickOrigin: Date {
        let fallback = Date(timeIntervalSinceReferenceDate: 0)
        if isPaused { return pausedAt ?? fallback }
        return focusGoal ?? studyAnchor ?? fallback
    }

    // MARK: - Session actions

    func start() {
        guard phase == .idle else { return }
        let now = Date.now
        startedAt = now
        studyAnchor = now
        pausedAt = nil
        breakCount = 0
        finishedBreakTime = 0
        lastCompletedLength = nil
        segments = [Segment(id: 0, kind: .study, start: now, end: nil)]
        phase = .running
    }

    func pause() {
        guard phase == .running else { return }
        let now = Date.now
        pausedAt = now
        openSegment(.rest, at: now)
        phase = .paused
    }

    func resume() {
        guard phase == .paused, let pausedAt else { return }
        let now = Date.now
        let gap = now.timeIntervalSince(pausedAt)
        studyAnchor = studyAnchor?.addingTimeInterval(gap)
        focusStart = focusStart?.addingTimeInterval(gap)
        focusGoal = focusGoal?.addingTimeInterval(gap)
        finishedBreakTime += gap
        breakCount += 1
        self.pausedAt = nil
        openSegment(.study, at: now)
        phase = .running
    }

    /// Start when idle, otherwise flip between running and paused.
    func toggle() {
        switch phase {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func end() {
        guard hasSession else { return }
        let length = studyElapsed()
        clear()
        lastCompletedLength = length
    }

    func reset() {
        clear()
        lastCompletedLength = nil
    }

    private func clear() {
        phase = .idle
        startedAt = nil
        studyAnchor = nil
        pausedAt = nil
        breakCount = 0
        finishedBreakTime = 0
        focusStart = nil
        focusGoal = nil
        segments = []
        isLocked = false
    }

    private func openSegment(_ kind: Segment.Kind, at date: Date) {
        if let last = segments.indices.last {
            segments[last].end = date
        }
        segments.append(Segment(id: segments.count, kind: kind, start: date, end: nil))
    }

    // MARK: - Focus block

    func startFocusBlock() {
        guard hasSession, focusDuration > 0 else { return }
        let begin = studyClock(at: .now)
        focusStart = begin
        focusGoal = begin.addingTimeInterval(focusDuration)
    }

    func clearFocusBlock() {
        focusStart = nil
        focusGoal = nil
        isLocked = false
    }

    // MARK: - Lab controls

    /// Pretend `seconds` have passed by sliding every timestamp into the past.
    func skip(_ seconds: TimeInterval) {
        guard hasSession else { return }
        startedAt = startedAt?.addingTimeInterval(-seconds)
        studyAnchor = studyAnchor?.addingTimeInterval(-seconds)
        pausedAt = pausedAt?.addingTimeInterval(-seconds)
        focusStart = focusStart?.addingTimeInterval(-seconds)
        focusGoal = focusGoal?.addingTimeInterval(-seconds)
        for index in segments.indices {
            segments[index].start = segments[index].start.addingTimeInterval(-seconds)
            segments[index].end = segments[index].end?.addingTimeInterval(-seconds)
        }
    }

    /// A running session that began 47 minutes ago with two breaks behind it.
    func loadSampleSession() {
        reset()
        let now = Date.now
        func minutesAgo(_ minutes: Double) -> Date {
            now.addingTimeInterval(-minutes * 60)
        }
        startedAt = minutesAgo(47)
        studyAnchor = minutesAgo(41)
        breakCount = 2
        finishedBreakTime = 6 * 60
        segments = [
            Segment(id: 0, kind: .study, start: minutesAgo(47), end: minutesAgo(29)),
            Segment(id: 1, kind: .rest, start: minutesAgo(29), end: minutesAgo(25)),
            Segment(id: 2, kind: .study, start: minutesAgo(25), end: minutesAgo(8)),
            Segment(id: 3, kind: .rest, start: minutesAgo(8), end: minutesAgo(6)),
            Segment(id: 4, kind: .study, start: minutesAgo(6), end: nil)
        ]
        phase = .running
    }
}
