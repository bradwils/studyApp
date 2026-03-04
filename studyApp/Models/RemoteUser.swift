//
//  RemoteUser.swift
//  studyApp
//
//  Created by brad wils on 17/2/26.
//


//Remote users only need an ID, display name, and friend status. Sensitive data isn’t required. If we need more information later, we can work with the ID. We don’t need to retrieve all their data.


struct RemoteUser: Codable {
    let id: String // Unique ID from the server (todo)
    var displayName: String
    var activeStatus: activeStatus //user state
    var isFriend: Bool
    var userPFPURL: String? //does not need to be grabbed everytime
    
}

enum activeStatus {
    case offline, break, online, studying
}
