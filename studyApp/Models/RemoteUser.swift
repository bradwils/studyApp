//
//  RemoteUser.swift
//  studyApp
//
//  Created by brad wils on 17/2/26.
//

import Foundation
import SwiftData


//Remote users only need an ID, display name, and friend status. Sensitive data isn’t required. If we need more information later, we can work with the ID. We don’t need to retrieve all their data.

@Model
final class RemoteUser {

    var remoteID: String
    #Unique<RemoteUser>([\.remoteID])

    var displayName: String
    var handle: String?
    var isFriend: Bool
    var profileURL: String?

    // What the server last told us, and when it told us. Both are needed — a status with no
    // timestamp can't be aged out, and a stale "studying" is worse than showing nothing.
    var userStatus: ActiveStatus
    var lastSeenAt: Date
    var syncedAt: Date

    // Denormalized from the remote session so the feed renders without a second fetch.
    // Storing the start instant rather than a formatted string lets any view compute elapsed
    // time live, and keeps it correct across backgrounding.
    var currentSubjectName: String?
    var currentSessionStartedAt: Date?

    var currentSessionDuration: TimeInterval? {
        guard let currentSessionStartedAt else { return nil }
        return Date.now.timeIntervalSince(currentSessionStartedAt)
    }

    var timeSinceLastSeen: TimeInterval { Date.now.timeIntervalSince(lastSeenAt) }

    // A pause is expected to be brief, so it loses credibility sooner than an active session
    // that has simply gone quiet.
    static let studyingStaleAfter: TimeInterval = 15 * 60
    static let pausedStaleAfter: TimeInterval = 5 * 60

    // Confidence in a cached status only ever decays — showing a friend as studying when they
    // closed the app an hour ago is the failure users actually notice.
    var displayStatus: ActiveStatus {
        switch userStatus {
        case .offline:
            return .offline
        case .paused:
            return timeSinceLastSeen > Self.pausedStaleAfter ? .offline : .paused
        case .online, .studying:
            return timeSinceLastSeen > Self.studyingStaleAfter ? .offline : userStatus
        }
    }

    init(
        remoteID: String,
        displayName: String,
        handle: String? = nil,
        userStatus: ActiveStatus = .offline,
        isFriend: Bool = false,
        profileURL: String? = nil,
        lastSeenAt: Date = .now,
        syncedAt: Date = .now,
        currentSubjectName: String? = nil,
        currentSessionStartedAt: Date? = nil
    ) {
        self.remoteID = remoteID
        self.displayName = displayName
        self.handle = handle
        self.userStatus = userStatus
        self.isFriend = isFriend
        self.profileURL = profileURL
        self.lastSeenAt = lastSeenAt
        self.syncedAt = syncedAt
        self.currentSubjectName = currentSubjectName
        self.currentSessionStartedAt = currentSessionStartedAt
    }
}


// MARK: - Server payload

// Kept separate from the @Model so the wire format can change without a SwiftData migration.
struct RemoteUserDTO: Codable, Identifiable {
    var id: String
    var displayName: String
    var handle: String?
    var status: ActiveStatus
    var profileURL: String?
    var lastSeenAt: Date
    var currentSubjectName: String?
    var currentSessionStartedAt: Date?
}

extension RemoteUser {

    convenience init(dto: RemoteUserDTO, isFriend: Bool, syncedAt: Date = .now) {
        self.init(
            remoteID: dto.id,
            displayName: dto.displayName,
            handle: dto.handle,
            userStatus: dto.status,
            isFriend: isFriend,
            profileURL: dto.profileURL,
            lastSeenAt: dto.lastSeenAt,
            syncedAt: syncedAt,
            currentSubjectName: dto.currentSubjectName,
            currentSessionStartedAt: dto.currentSessionStartedAt
        )
    }

    // isFriend is deliberately not updated here — friendship is local state the feed endpoint
    // has no authority over.
    func apply(_ dto: RemoteUserDTO, syncedAt: Date = .now) {
        displayName = dto.displayName
        handle = dto.handle
        userStatus = dto.status
        profileURL = dto.profileURL
        lastSeenAt = dto.lastSeenAt
        currentSubjectName = dto.currentSubjectName
        currentSessionStartedAt = dto.currentSessionStartedAt
        self.syncedAt = syncedAt
    }
}
