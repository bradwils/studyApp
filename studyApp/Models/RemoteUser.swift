//
//  RemoteUser.swift
//  studyApp
//
//  Created by brad wils on 17/2/26.
//

import Foundation
import SwiftData


//Remote users will be filled from a remote server, requiring a remoteID, displayName, isFriend, as well as basic metadata (their status, Sensitive data isn’t required. If we need more information later, we can work with the ID. We don’t need to retrieve all their data.


@Model
final class RemoteUser {

	//This needs to be remote, but controlled server-side (not client side), no unique attribute needed.
    var remoteID: String

    var displayName: String
    var handle: String
    var isFriend: Bool

    // What the server last told us, and when it told us. Both are needed — a status with no
	
    var userStatus: ActiveStatus? //offline / paused / online / studying
	//we can update this to prevent stale data on server side.
    var lastSeenAt: Date?
	var timeSinceLastSeen: TimeInterval { Date.now.timeIntervalSince(lastSeenAt ?? .distantPast) }
	

    var currentSessionStartedAt: Date?

	
	var syncedAt: Date


    init(
        remoteID: String,
        displayName: String,
        handle: String,
		isFriend: Bool = false,
        userStatus: ActiveStatus = .offline,
        lastSeenAt: Date = .now,
        currentSubjectName: String? = nil,
        currentSessionStartedAt: Date? = nil,
		syncedAt: Date = .now
    ) {
        self.remoteID = remoteID
        self.displayName = displayName
        self.handle = handle
		self.isFriend = isFriend
        self.userStatus = userStatus
        self.lastSeenAt = lastSeenAt
        self.currentSubjectName = currentSubjectName
        self.currentSessionStartedAt = currentSessionStartedAt
		self.syncedAt = syncedAt
    }
}


// MARK: TODO - Server payload (data-transfer-object)
