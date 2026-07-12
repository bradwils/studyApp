// Stopwatch.swift
// studyApp
//
// Value-type stopwatch used by StudyTrackingViewModel to track net study time.

import Foundation

//our stopwatch works by having a single point of truth, our adjustedStartTimeForAnchor, which is updated whenever breaks are changed by shifting that timestamp forward by however long our breaks are. This means that we continue to push this time forward

struct Stopwatch {
    var lastPausedAt: Date?
    var stopwatchIsRunning: Bool = false
    var startedAt: Date? //check that this is valid!


    var adjustedStartTimeForAnchor: Date?

    var totalRunningTime: TimeInterval {
        guard let anchor = adjustedStartTimeForAnchor else { return 0 }
        if stopwatchIsRunning {
            return Date.now.timeIntervalSince(anchor)
        } else {
            return lastPausedAt!.timeIntervalSince(anchor) //safe to unwrap as we can only pause if we've started
        }
    }


    //MARK: Functions


    init() {
        initialise();
    }

    //start the stopwatch
    mutating func initialise() {
        self.stopwatchIsRunning = true
        self.startedAt = Date.now
        self.adjustedStartTimeForAnchor = self.startedAt!
    }
    


    mutating func endBreak() {
        let breakLength = Date.now.timeIntervalSince(lastPausedAt!) //safe to unwrap as we cna only resume after we've paused
        self.stopwatchIsRunning = true
        self.adjustedStartTimeForAnchor = adjustedStartTimeForAnchor!.addingTimeInterval(breakLength)
    }

    mutating func startBreak() {
        self.lastPausedAt = Date.now
        self.stopwatchIsRunning = false
    }



    //end stopwatch
    mutating func end() {
        self.stopwatchIsRunning = false
        self.lastPausedAt = Date.now
    }
}
