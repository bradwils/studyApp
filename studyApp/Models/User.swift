//
//  User.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//

import Foundation
import SwiftData


@Model
class UserProfile { //holds all local data, as well as an optional link to an external account
    var id: UUID
    var userHandle: String? //todo, register online later
    var userStatus: ActiveStatus
    var profileName: String
    var userProfilePicturePath: String?
    var authProvider: AuthProvider
    var createdAt: Date
    var subjects: [Subject]?
    var studySessions: [StudySession] = [] //empty for now
    
    init(id: UUID, userHandle: String? = nil, userStatus: ActiveStatus, profileName: String, userProfilePicturePath: String? = nil, authProvider: AuthProvider, createdAt: Date = Date.now, subjects: [Subject], studySessions: [StudySession]) {
        self.id = id
        self.userHandle = userHandle
        self.userStatus = userStatus
        self.profileName = profileName
        self.userProfilePicturePath = userProfilePicturePath
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.subjects = subjects
        self.studySessions = studySessions
    }


}

enum AuthProvider:String, Codable {
    case apple
    case google
    case emailPassword
    case custom
    case anon //for no sign in
}

enum ActiveStatus: String, Codable {
    case offline, paused, online, studying
}
