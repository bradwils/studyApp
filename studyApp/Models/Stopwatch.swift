// Stopwatch.swift
// studyApp
//
// Value-type stopwatch used by StudyTrackingViewModel to track net study time.

import Foundation

struct Stopwatch {
    var lastPausedAt: Date?
    var stopwatchIsRunning: Bool = false
    var startedAt: Date
    var lastBreakStartTime: Date?
    var previousBreaksLength: TimeInterval = 0

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }

    var totalStudyingTime: TimeInterval {
        let wallEnd = lastPausedAt ?? .now
        return wallEnd.timeIntervalSince(startedAt) - previousBreaksLength
    }

    mutating func initiate() {
        self.startedAt = .now
        self.stopwatchIsRunning = true
    }

    // Pausing starts tracking the break time so resume() can re-anchor correctly.
    mutating func pause() {
        self.lastPausedAt = .now
        self.stopwatchIsRunning = false
    }

    mutating func resume() {
        self.previousBreaksLength = previousBreaksLength + (lastPausedAt?.timeIntervalSinceNow ?? 0)
        self.stopwatchIsRunning = true
    }
    
    mutating func startBreak() {
        
    }
}
