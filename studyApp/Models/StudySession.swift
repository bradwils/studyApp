//  StudySession.swift
//  studyApp
//
//  Data models for study sessions.

import Foundation
import SwiftData

@Model
class StudySession {
    var id: UUID
    var subject: Subject?
    var subjectName: String?
    var startedAt: Date
    var endedAt: Date?
    var isPaused: Bool

    //could probably combine these two into one property which isn't tracked but computed and displayed on the focus screen
    var lastResumedAt: Date 
    var lastPausedAt: Date?

    var totalActiveDuration: TimeInterval
    var totalBreakDuration: TimeInterval
    var breaks: [StudyBreak]
    var StudyPartners: [String] // placeholder for other users in the session
    var location: SessionLocation?
    var studyScore: Int? // 0...10 rating at completion
    var notes: String?
    var interruptionCount: Int

    // Future analytics: screen time per app/category can be attached here once available.

    init(
        id: UUID = UUID(),
        subject: Subject? = nil,
        subjectName: String? = nil,
        startedAt: Date = Date.now,
        endedAt: Date? = nil,
        isPaused: Bool = false,
        lastResumedAt: Date = Date(),
        lastPausedAt: Date? = nil,
        activeDuration: TimeInterval = 0, //computed later
        totalBreakDuration: TimeInterval = 0, //computed later
        breaks: [StudyBreak] = [],
        companions: [String] = [],
        location: SessionLocation? = nil,
        studyScore: Int? = nil,
        notes: String? = nil,
        interruptionCount: Int = 0
    ) {
        self.id = id
        self.subject = subject
        self.subjectName = subject?.name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isPaused = isPaused
        self.lastResumedAt = lastResumedAt
        self.lastPausedAt = lastPausedAt
        self.totalActiveDuration = activeDuration
        self.totalBreakDuration = totalBreakDuration
        self.breaks = breaks
        self.StudyPartners = companions
        self.location = location
        self.studyScore = studyScore
        self.notes = notes
        self.interruptionCount = interruptionCount ?? 0
    }

    var totalElapsed: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    var runningActiveDuration: TimeInterval {
        if isPaused {
            return totalActiveDuration
        } else {
            return totalActiveDuration + Date().timeIntervalSince(lastResumedAt)
        }
    }
}


@Model
class SessionLocation { //optional placeholder for future location tagging
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var sessionCount: Int
    
    init(locationName: String, latitude: Double? = nil, longitude: Double? = nil, sessionCount: Int = 0) {
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.sessionCount = sessionCount
    }
        
    //second type without long/lat
        
    init(locationName: String, sessionCount: Int = 0) {
        self.locationName = locationName
        self.latitude = nil
        self.longitude = nil
        self.sessionCount = sessionCount
    }
}

@Model
class Distraction {
    var apps: [Int] //placeholder -> will be app identifiers later
    var totalTime: TimeInterval
    var rating: Int
    
    init(apps: [Int], totalTime: TimeInterval, rating: Int) {
        self.apps = apps
        self.totalTime = totalTime
        self.rating = rating
    }
}

@Model
class StudyBreak { //records a single breakPeriod
    var startedAt: Date
    var endedAt: Date

    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) } //computed property
    
    init(id: UUID, startedAt: Date, endedAt: Date, StudySession: StudySession) {
        
        self.startedAt = startedAt
        self.endedAt = endedAt
        
        //StudySession.insert(thisBreak) <--- TODO; add to current session
        
        
    }
}

/// Represents an individual study session, both while active and once completed.
