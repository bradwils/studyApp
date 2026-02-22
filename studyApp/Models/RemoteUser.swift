//
//  RemoteUser.swift
//  studyApp
//
//  Created by brad wils on 17/2/26.
//


//remote users only need to be identified by an ID, their displayname, and whether or not they're a friend. There isn't any sensitive data needed about them. if we want more info or something similar later down the line, we can just work with the ID. no need to pull everything.


struct RemoteUser: Codable {
    let id: String // Unique ID from the server (todo)
    var displayName: String
    var isFriend: Bool
    var userPFPURL: String? //does not need to be grabbed everytime
    
}
