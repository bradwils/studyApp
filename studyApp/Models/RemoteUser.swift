//
//  RemoteUser.swift
//  studyApp
//
//  Created by brad wils on 17/2/26.
//

import SwiftData


//Remote users only need an ID, display name, and friend status. Sensitive data isn’t required. If we need more information later, we can work with the ID. We don’t need to retrieve all their data.

@Model
final class RemoteUser  {
    var remoteID: String // Unique ID from the server (todo)
    var displayName: String
    var userStatus: ActiveStatus // user state
    var isFriend: Bool
    var profileURL: String?
    
    
    
    init(id: String, displayName: String, userStatus: ActiveStatus, isFriend: Bool, userPFPURL: String? = nil) {
        self.remoteID = id
        self.displayName = displayName
        self.userStatus = userStatus
        self.isFriend = isFriend
        self.profileURL = userPFPURL
    }
}

