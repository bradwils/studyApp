//  StudyTracking.swift
//  studyApp
//
//  Models for tracking study sessions.

import Foundation
import Combine

/// Represents an in-flight study timer session.
struct StudyTimer: Identifiable, Codable {
    var id: UUID = UUID()
    var subject: String
    var start: Date = Date()
    var end: Date?
    var locationLat: Double = 0
    var locationLon: Double = 0
    var breaks: [Date] = []
    var lastPause: Date?
    var isPaused: Bool = false
}

/// Represents a completed study session with extra details once it has ended.
struct CompleteStudySession: Identifiable, Codable {
    var id: UUID = UUID()
    var timer: StudyTimer
    var end: Date
    var focusQuality: Int
    var locationConfirmed: Bool?
    var otherUsers: [String]?
    var focusedTime: TimeInterval?
    var breaks: [Date]?
    
    var totalDuration: TimeInterval {
        max(0, end.timeIntervalSince(timer.start))
    }
    
    init(timer: StudyTimer,
         end: Date,
         focusQuality: Int,
         locationConfirmed: Bool? = nil,
         otherUsers: [String]? = nil,
         focusedTime: TimeInterval? = nil,
         breaks: [Date]? = nil) {
        var updatedTimer = timer
        updatedTimer.end = end
        self.timer = updatedTimer
        self.end = end
        self.focusQuality = focusQuality
        self.locationConfirmed = locationConfirmed
        self.otherUsers = otherUsers
        self.focusedTime = focusedTime
        self.breaks = breaks
    }
}

struct StudySessionFactory {
    static func convert(timer: StudyTimer, end: Date, focusQuality: Int) -> CompleteStudySession {
        CompleteStudySession(timer: timer, end: end, focusQuality: focusQuality)
    }
}

// MARK: - Controller

final class StudyTrackingController: ObservableObject {
    enum State {
        case idle, running, paused, finished
    }

    @Published private(set) var timer: StudyTimer
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var state: State = .idle
    @Published var completedSession: CompleteStudySession?
    @Published private(set) var pausedDuration: TimeInterval = 0
    @Published private(set) var breakLoggedDuringPause: Bool = false

    let subjectOptions = ["Deep Work", "Math Revision", "Reading", "Research"]
    private var ticker: AnyCancellable?
    private var breakWatcher: AnyCancellable?
    private var baselineDate = Date()
    private var pauseStarted: Date?
    private let breakThreshold: TimeInterval = 3 * 60

    init(timer: StudyTimer = StudyTimer(subject: "Deep Work")) {
        self.timer = timer
    }

    var subject: String { timer.subject }
    var breakCount: Int { timer.breaks.count }
    var statusText: String {
        switch state {
        case .idle:
            return "Ready when you are"
        case .running:
            return "Staying focused"
        case .paused:
            return breakLoggedDuringPause ? "On a break" : "Paused"
        case .finished:
            return "Session complete"
        }
    }

    func setSubject(_ newSubject: String) {
        guard timer.subject != newSubject else { return }
        timer.subject = newSubject
    }

    func start() {
        let now = Date()
        timer.start = now
        timer.end = nil
        timer.breaks = []
        timer.isPaused = false
        timer.lastPause = nil
        elapsed = 0
        pauseStarted = nil
        pausedDuration = 0
        breakLoggedDuringPause = false
        completedSession = nil
        baselineDate = now
        state = .running
        startTicker()
    }

    func pause() {
        guard state == .running else { return }
        stopTicker()
        pauseStarted = Date()
        timer.lastPause = pauseStarted
        timer.isPaused = true
        state = .paused
        breakLoggedDuringPause = false
        pausedDuration = 0
        startBreakWatcher()
    }

    func resume() {
        guard state == .paused else { return }
        stopBreakWatcher()
        timer.isPaused = false
        timer.lastPause = nil
        pauseStarted = nil
        pausedDuration = 0
        breakLoggedDuringPause = false
        baselineDate = Date().addingTimeInterval(-elapsed)
        state = .running
        startTicker()
    }

    func togglePrimaryAction() {
        switch state {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        case .finished:
            start()
        }
    }

    func endSession() {
        guard state == .paused else { return }
        stopTicker()
        stopBreakWatcher()
        let endDate = Date()
        timer.end = endDate
        let session = StudySessionFactory.convert(timer: timer, end: endDate, focusQuality: 7)
        var enrichedSession = session
        enrichedSession.focusedTime = elapsed
        enrichedSession.breaks = timer.breaks
        completedSession = enrichedSession
        state = .finished
    }

    func reset() {
        stopTicker()
        stopBreakWatcher()
        elapsed = 0
        pauseStarted = nil
        pausedDuration = 0
        breakLoggedDuringPause = false
        state = .idle
        timer.end = nil
        timer.breaks = []
        timer.isPaused = false
        completedSession = nil
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                elapsed = Date().timeIntervalSince(baselineDate)
            }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func startBreakWatcher() {
        stopBreakWatcher()
        breakWatcher = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let pauseStarted else { return }
                let duration = Date().timeIntervalSince(pauseStarted)
                pausedDuration = duration
                if duration >= breakThreshold && !breakLoggedDuringPause {
                    timer.breaks.append(pauseStarted)
                    breakLoggedDuringPause = true
                }
            }
    }

    private func stopBreakWatcher() {
        breakWatcher?.cancel()
        breakWatcher = nil
    }

    deinit {
        stopTicker()
        stopBreakWatcher()
    }
}

// MARK: - Formatting helpers

extension TimeInterval {
    var formattedClock: String {
        let totalSeconds = Int(self)
        let minutes = (totalSeconds / 60) % 60
        let seconds = totalSeconds % 60
        let hours = totalSeconds / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
