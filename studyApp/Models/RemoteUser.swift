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
    // timestamp can't be aged out, and a stale "studying" is worse than showing nothing.
    var userStatus: ActiveStatus?
	var displayStatus: String
    var lastSeenAt: Date?


    // Denormalized from the remote session so the feed renders without a second fetch.
    // Storing the start instant rather than a formatted string lets any view compute elapsed
    // time live, and keeps it correct across backgrounding.
    var currentSubjectName: String?
    var currentSessionStartedAt: Date?

    var currentSessionDuration: TimeInterval? {
        guard let currentSessionStartedAt else { return nil }
        return Date.now.timeIntervalSince(currentSessionStartedAt)
    }

    var timeSinceLastSeen: TimeInterval { Date.now.timeIntervalSince(lastSeenAt ?? .distantPast) }

    // Confidence in a cached status only ever decays — showing a friend as studying when they
    // closed the app an hour ago is the failure users actually notice.

	
	var syncedAt: Date


    init(
        remoteID: String,
        displayName: String,
        handle: String,
		isFriend: Bool = false,
        userStatus: ActiveStatus = .offline,
		displayStatus: String,
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
		self.displayStatus = displayStatus
        self.lastSeenAt = lastSeenAt
        self.currentSubjectName = currentSubjectName
        self.currentSessionStartedAt = currentSessionStartedAt
		self.syncedAt = syncedAt
    }
}


// MARK: TODO - Server payload (data-transfer-object)
