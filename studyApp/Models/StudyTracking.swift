//  StudyTracking.swift
//  studyApp
//
//  Models for tracking study sessions.

import Foundation
import SwiftUI
import Combine

/// Represents a completed study session.
struct CompleteStudySession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var subject: String
    var start: Date
    var end: Date
    var locationLat: Double
    var locationLon: Double
    var locationConfirmed: Bool?
    var OtherUsers: [String]?
    var focusedTime: TimeInterval?
    var breaks: [Date]?
    var isPaused: Bool = false
    var intensity: Int
}


/// Represents a study timer session that has been started.
struct StartStudyTimer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var subject: String
    var start: Date
    var locationLat: Double
    var locationLon: Double
}
