//  TimeInterval+Formatting.swift
//  studyApp
//
//  Formatting helpers for TimeInterval.

import Foundation

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
