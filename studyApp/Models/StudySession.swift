//  StudySession.swift
//  studyApp
//
//  Data models for study sessions.

import Foundation
import SwiftData


// MARK: - SessionLocation
@Model
final class SessionLocation {
    var locationDescription: String?
    var latitude: Double?
    var longitude: Double?
    var locationLabel: String

    init(locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil, locationLabel: String) {
        self.locationDescription = locationDescription
        self.latitude = latitude
        self.longitude = longitude
        self.locationLabel = locationLabel
    }

    convenience init(latitude: Double, longitude: Double) {
        self.init(latitude: latitude, longitude: longitude, locationLabel: "")
    }
}


// MARK: - StudyBreak
@Model
final class StudyBreak {
    var startedAt: Date
    var endedAt: Date?

    // Returns 0 while break is still in progress (no endedAt yet)
    var duration: TimeInterval {
        guard let endedAt else { return 0 }
        return endedAt.timeIntervalSince(startedAt)
    }

    init(startedAt: Date = Date(), endedAt: Date? = nil) {
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}


// MARK: - StudySession
@Model
final class StudySession: Identifiable {
    var id: UUID

    // References a subject but doesn't own it — nullify so deleting a subject doesn't delete sessions
    @Relationship(deleteRule: .nullify) //
    var subject: Subject?
    var subjectName: String?  // preserved if subject is later deleted

    var startedAt: Date
    var endedAt: Date?
    var lastPausedAt: Date?

    // Session owns its breaks and location — cascade deletes them when session is removed
    @Relationship(deleteRule: .cascade) //delete break --> delete connected StudyBreaks
    var breaks: [StudyBreak]

    @Relationship(deleteRule: .cascade) //delete sessionLocation --> delete connected SessionLocation
    var location: SessionLocation?

    var friends: [String]?           // placeholder for other users in the session
    var studyScore: Int?             // 0...10 rating at completion
    var notes: String?
    var interruptionCount: Int
    var totalBreakDuration: TimeInterval?

    var totalDuration: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    var totalActiveDuration: TimeInterval {
        guard endedAt != nil else { return totalDuration }
        let breaksTotal = breaks.reduce(0) { $0 + $1.duration }
        return totalDuration - breaksTotal
    }

    init(
        id: UUID = UUID(),
        subject: Subject? = nil,
        subjectName: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        lastPausedAt: Date? = nil,
        totalBreakDuration: TimeInterval? = 0,
        breaks: [StudyBreak] = [],
        friends: [String]? = [],
        location: SessionLocation? = nil,
        studyScore: Int? = nil,
        notes: String? = nil,
        interruptionCount: Int = 0
    ) {
        self.id = id
        self.subject = subject
        self.subjectName = subjectName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.lastPausedAt = lastPausedAt
        self.totalBreakDuration = totalBreakDuration
        self.breaks = breaks
        self.friends = friends
        self.location = location
        self.studyScore = studyScore
        self.notes = notes
        self.interruptionCount = interruptionCount
    }
    
    init(
        id: UUID = UUID(),
        subject: Subject,
        subjectName: String?,
        startedAt: Date,
        breaks: [StudyBreak] = [],
        friends: [String] = []
    ) {
        self.id = id
        self.subject = subject
        self.subjectName = subjectName
        self.startedAt = startedAt
        self.endedAt = nil
        self.lastPausedAt = nil
        self.totalBreakDuration = 0
        self.breaks = breaks
        self.location = nil
        self.friends = friends
        self.studyScore = nil
        self.notes = nil
        self.interruptionCount = 0
    }
}
