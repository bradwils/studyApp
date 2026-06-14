//
//  User.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//

import Foundation
import SwiftUI


struct UserProfile { //holds all local data, as well as an optional link to an external account
    var id: UUID
    var userHandle: String? //todo, register online later
    var userStatus: ActiveStatus
    var profileName: String
    var userProfilePicturePath: String?
    var auth: AuthState
    var createdAt: Date
    var isPaused: Bool
    var lastResumedAt: Date
    var lastActiveAt: Date
    var subjects: [Subject]
    var studySessions: [StudySession] = []


}


struct AuthState: Codable {
    var service: AuthProvider? //
    var lastSignInAt: Date?
}

enum AuthProvider: String, Codable, CaseIterable {
    case apple
    case google
    case emailPassword
    case custom
    case anon //for no sign in
}

enum ActiveStatus: String, Codable {
    case offline, paused, online, studying
}
