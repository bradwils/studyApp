//
//  User.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class UserProfile { // holds all local data, as well as an optional link to an external account
    // SwiftData can synthesize an identifier; keep a stable UUID if you need to share across systems
    var id: UUID

    var userHandle: String? // todo, register online later

    var userStatus: ActiveStatus

    var profileName: String
    var userProfilePicturePath: String?

    var auth: AuthState?

    var createdAt: Date
    var isPaused: Bool

    // This sounds like a timestamp; use Date? instead of Bool
    var lastResumedAt: Date?

    var lastActiveAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var subjects: [Subject]

    @Relationship(deleteRule: .cascade)
    var studySessions: [StudySession]

    init(
        id: UUID = UUID(),
        userHandle: String? = nil,
        userStatus: ActiveStatus = .offline,
        profileName: String,
        userProfilePicturePath: String? = nil,
        auth: AuthState? = nil,
        createdAt: Date = .now,
        isPaused: Bool = false,
        lastResumedAt: Date? = nil,
        lastActiveAt: Date = .now,
        subjects: [Subject] = [],
        studySessions: [StudySession] = []
    ) {
        self.id = id
        self.userHandle = userHandle
        self.userStatus = userStatus
        self.profileName = profileName
        self.userProfilePicturePath = userProfilePicturePath
        self.auth = auth
        self.createdAt = createdAt
        self.isPaused = isPaused
        self.lastResumedAt = lastResumedAt
        self.lastActiveAt = lastActiveAt
        self.subjects = subjects
        self.studySessions = studySessions
    }
}

struct AuthState: Codable {
    var service: AuthProvider?
    var lastSignInAt: Date?
}

enum AuthProvider: Codable {
    case apple
    case google
    case emailPassword
    case custom
    case anon
}

enum ActiveStatus: String, Codable {
    case offline
    case online
    case active
    case inactive
    case unknown
}
