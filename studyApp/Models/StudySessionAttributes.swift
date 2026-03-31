//
//  StudySessionAttributes.swift
//  studyApp
//
//  Live Activity attributes for displaying active study sessions
//

import Foundation
import ActivityKit

/// Attributes for the Study Session Live Activity
/// These define the static and dynamic data for the Live Activity
struct StudySessionAttributes: ActivityAttributes {
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        /// The name of the subject being studied
        var subjectName: String

        /// The subject code (e.g., "MATH101")
        var subjectCode: String

        /// The current session duration in seconds
        var sessionDuration: TimeInterval

        /// Whether the session is currently paused
        var isPaused: Bool

        /// The time when the session started
        var startedAt: Date

        /// Total number of interruptions in this session
        var interruptionCount: Int

        /// Total break duration in seconds
        var totalBreakDuration: TimeInterval
    }

    /// The unique identifier for this study session
    var sessionId: String
}
