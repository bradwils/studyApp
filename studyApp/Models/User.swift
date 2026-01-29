//
//  User.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//

import Foundation
import SwiftUI


struct UserProfile: Codable { //holds all local data, as well as an optional link to an external account
    let id: UUID
    var userHandle: String //todo, register online later
    var profileName: String
    var userProfilePicturePath: String?
    var auth: AuthState
    var createdAt: Date
    var lastActiveAt: Date
    
}

\
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
