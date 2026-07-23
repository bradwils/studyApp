//  StudySession.swift
//  studyApp
//
//  Data models for study sessions.

import Foundation
import SwiftData

import os
//let logger = Logger()


// MARK: - SessionLocation
@Model
final class SessionLocation { //optional placeholsder for future location tagging
    var locationDescription: String?
    var latitude: Double?
    var longitude: Double?
    var locationLabel: String
    
    // Designated initializer
    init(locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil, locationLabel: String) {
        self.locationDescription = locationDescription
        self.latitude = latitude
        self.longitude = longitude
        self.locationLabel = locationLabel
    }
    
    // Convenience initializer for pure location
    convenience init(latitude: Double, longitude: Double) {
        self.init(locationDescription: nil, latitude: latitude, longitude: longitude, locationLabel: "")
    }
    
    // Convenience initializer for placeholder
    convenience init() {
        self.init(locationDescription: "Placeholder Description", latitude: 0.0, longitude: 0.0, locationLabel: "Placeholder Label")
    }
}

//fquerbuadv    38u hwr fju wefn\






//MARK: StudyBreak
@Model
final class StudyBreak { //records a single breakPeriod
    
    //convert startedAt and endedAt from TimeInterval to Date.
    var startedAt: Date
    var endedAt: Date?

    //duration of break; equal to 0 if it's still in progress (no value for endedAt), otherwise we'll update and save the break when we've ended it.
    var duration: TimeInterval{
        if let endedAt = endedAt {
            return endedAt.timeIntervalSince(startedAt)
        } else {
            return 0
        }
    }
    
    init(startedAt: Date, endedAt: Date) {
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    //if initiated empty, we can start it but have no end attatched.
    init() {
        self.startedAt = Date.now
    }
}


/// Represents an individual study session, both while active and once completed.
@Model
final class StudySession: Identifiable {
    var id: UUID
    
    var subject: Subject?  //optional
    var subjectName: String? //optional
    var startedAt: Date
    var endedAt: Date? //optional

    var lastPausedAt: Date? //optional

    var totalActiveDuration: TimeInterval { //start to either end time or now MINUS (forEach in breaks --> duration)
        //if we this is a finished studySession
        if let endedAt {
            var breaksTotal: TimeInterval = 0;

            (breaks ?? []).forEach { each in //safely fallback if no breaks
                breaksTotal += each.duration
            }
            //logger.log("breaks added up to \(breaksTotal)")


            //return total duration minus any breaks. if none, then it's just the totalDuration.
            return totalDuration - breaksTotal;
        }
        
        //if session is inprog
        return totalDuration;
	
    }
    var totalBreakDuration: TimeInterval?
    
    var breaks: [StudyBreak]?
    var friends: [String]? // placeholder for other users in the session
    var location: SessionLocation?
    var studyScore: Int? // 0...10 rating at completion
    var notes: String?
    
    var interruptionCount: Int
    
    //total duratrion of session between end date - start OR current date - start.
    var totalDuration: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }
    
    

    // Future analytics: screen time per app/category can be attached here once available.
    
    
    //Default initialiser, parsing all required parameters, & optional for optionals.
    init(
        id: UUID = UUID(),
        subject: Subject,
        subjectName: String?,
        startedAt: Date,
        endedAt: Date?,
        lastPausedAt: Date?,
        activeDuration: TimeInterval,
        totalBreakDuration: TimeInterval?,
        breaks: [StudyBreak]?,
        friends: [String] = [], //empty for now
        location: SessionLocation?,
        studyScore: Int?,
        notes: String?,
        interruptionCount: Int?
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
        self.interruptionCount = interruptionCount ?? 0
    }

    convenience init() {
        self.init(
            subject: nil,
            subjectName: nil,
            startedAt: Date(),
            endedAt: nil,
            lastPausedAt: nil,
            activeDuration: 0,
            totalBreakDuration: nil,
            breaks: [],
            location: nil,
            studyScore: nil,
            notes: nil,
            interruptionCount: 0
        )
    }
}
