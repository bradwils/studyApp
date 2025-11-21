//  StudyTrackingModel.swift
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

