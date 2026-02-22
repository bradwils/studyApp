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
    var isPaused: Bool
    var lastResumedAt: Bool
    var lastActiveAt: Date
    var subjects: [Subject]
    var studySessions: [StudySession] = []


    func storeStudySessionsLocally() { ///UNTESTED CODE
        // Encode the sessions array and write it to the app's Documents directory.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
 ///UNTESTED CODE
        do {
            let data = try encoder.encode(studySessions)
            let fm = FileManager.default
            let docsURL = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = docsURL.appendingPathComponent("studySessions_\(id.uuidString).json")
 ///UNTESTED CODE
            try data.write(to: fileURL, options: [.atomic])
            #if DEBUG
            print("Stored study sessions to: \(fileURL.path)")
            #endif
        } catch {
            print("Failed to store study sessions: \(error)")
        }
         ///UNTESTED CODE
    }
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
