import Foundation
import SwiftData

// Stores only what happened; whether the block finished or was cut short is derived
// from the session's sections by `StudyTimeline`, so the record never needs rewriting.
@Model
final class FocusBlock {
    var startedAt: Date
    var endedAt: Date?
    var targetDuration: TimeInterval

    init(startedAt: Date, endedAt: Date? = nil, targetDuration: TimeInterval) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.targetDuration = targetDuration
    }
}
