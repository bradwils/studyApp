//  StudyTracking.swift
//  first
//
//  Basic models and a timer manager for tracking study sessions.
//  This file defines data models for study sessions and a central store (StudyTimerStore) 
//  to manage timer state, session logging, and daily totals. It uses SwiftUI's ObservableObject 
//  for reactive UI updates and follows good practices like encapsulation, error handling, and 
//  memory management to ensure reliability in a real-time timer app.

import Foundation
import SwiftUI
import Combine

// A single completed study session
// This struct represents a logged study session. It's Codable for easy JSON serialization 
// (e.g., saving to disk), Identifiable for SwiftUI lists, and Hashable for use in sets or 
// dictionaries. Using UUID ensures unique IDs without manual management.
struct CompleteStudySession: Identifiable, Codable, Hashable {
    //codable: can go too and from json
    var id: UUID = UUID()
    var subject: String
    
    var start: Date //start timestamp
    var end: Date //end timestamp
    
    var locationLat: Double
    var locationLon: Double
    var locationConfirmed: Bool?
    //var locationObject: mapsObject? -> have a mapobject (library, school, home etc)
    
    
    var OtherUsers: [String]? //optional list of other users that you were studying with
    var focusedTime: TimeInterval? //optional focused time within the session
    var breaks: [Date]? //timestamps of when user time is not counted
    var isPaused: Bool = false
    //var distractedTime TODO; screen time API
    var intensity: Int //be like 0-3, so no restrictions, light, moderate, and then max (nothing else allowed)

}



struct startStudyTimer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var subject: String
    var start: Date
    //var locationObject: mapsObject?
    
    var locationLat: Double
    var locationLon: Double

}



