import Foundation
import Observation

enum V4Segment: String, CaseIterable {
    case now = "Now"
    case thisWeek = "This week"
}

@Observable
final class SocialV4PreviewModel {
    let me: SocialV4Mock.Me
    let loadedAt: Date
    private(set) var session: SocialV4Mock.Session?
    private(set) var pausedAt: Date?
    private(set) var suggestions: [SocialV4Mock.Friend]

    private let sessionTemplate: SocialV4Mock.Session
    private var baseFriends: [SocialV4Mock.Friend]
    private var sessionStart: Date
    private var bankedTodaySeconds: Int

    init(mock: SocialV4Mock = .load(), now: Date = .now) {
        me = mock.me
        loadedAt = now
        session = mock.session
        sessionTemplate = mock.session
        suggestions = mock.suggestions
        baseFriends = mock.friends
        sessionStart = now.addingTimeInterval(-TimeInterval(mock.session.elapsedSeconds))
        bankedTodaySeconds = mock.me.todaySeconds - mock.session.elapsedSeconds
    }

    var isPaused: Bool { pausedAt != nil }

    var sessionTimerRange: ClosedRange<Date> {
        sessionStart...sessionStart.addingTimeInterval(24 * 3600)
    }

    func sessionElapsed(at date: Date) -> Int {
        guard session != nil else { return 0 }
        return Self.wholeSeconds(from: sessionStart, to: pausedAt ?? date)
    }

    func togglePause(at date: Date = .now) {
        guard session != nil else { return }
        if let pausedAt {
            sessionStart = sessionStart.addingTimeInterval(date.timeIntervalSince(pausedAt))
            self.pausedAt = nil
        } else {
            pausedAt = date
        }
    }

    func endSession(at date: Date = .now) {
        guard session != nil else { return }
        bankedTodaySeconds += sessionElapsed(at: date)
        session = nil
        pausedAt = nil
    }

    func startSession(at date: Date = .now) {
        guard session == nil else { return }
        session = sessionTemplate
        sessionStart = date
    }

    var friends: [SocialV4Mock.Friend] {
        baseFriends.map { friend in
            guard friend.isCurrentUser else { return friend }
            var row = friend
            row.status = session == nil ? .online : (isPaused ? .paused : .studying)
            return row
        }
    }

    var stripFriends: [SocialV4Mock.Friend] {
        let others = friends.filter { !$0.isCurrentUser }
        let live = others
            .filter { $0.isLive }
            .sorted { ($0.sessionSeconds ?? 0) > ($1.sessionSeconds ?? 0) }
        let paused = others.filter { $0.status == .paused }
        return live + paused
    }

    func listFriends(for segment: V4Segment) -> [SocialV4Mock.Friend] {
        switch segment {
        case .now: friends.sorted { $0.todaySeconds > $1.todaySeconds }
        case .thisWeek: friends.sorted { $0.weekSeconds > $1.weekSeconds }
        }
    }

    var friendCount: Int {
        baseFriends.filter { !$0.isCurrentUser }.count
    }

    func friend(id: String) -> SocialV4Mock.Friend? {
        friends.first { $0.id == id }
    }

    func add(_ suggestion: SocialV4Mock.Friend) {
        guard let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) else { return }
        baseFriends.append(suggestions.remove(at: index))
    }

    func todaySeconds(for friend: SocialV4Mock.Friend, at date: Date) -> Int {
        if friend.isCurrentUser {
            return bankedTodaySeconds + sessionElapsed(at: date)
        }
        if friend.status == .studying {
            return friend.todaySeconds + Self.wholeSeconds(from: loadedAt, to: date)
        }
        return friend.todaySeconds
    }

    func weekSeconds(for friend: SocialV4Mock.Friend, at date: Date) -> Int {
        friend.weekSeconds + (todaySeconds(for: friend, at: date) - friend.todaySeconds)
    }

    func breakSeconds(for friend: SocialV4Mock.Friend, at date: Date) -> Int {
        if friend.isCurrentUser {
            guard let pausedAt else { return 0 }
            return Self.wholeSeconds(from: pausedAt, to: date)
        }
        if friend.status == .paused {
            return (friend.breakSeconds ?? 0) + Self.wholeSeconds(from: loadedAt, to: date)
        }
        return 0
    }

    func sessionStartDate(for friend: SocialV4Mock.Friend) -> Date? {
        guard !friend.isCurrentUser, friend.status == .studying else { return nil }
        return loadedAt.addingTimeInterval(-TimeInterval(friend.sessionSeconds ?? 0))
    }

    private static func wholeSeconds(from start: Date, to end: Date) -> Int {
        max(0, Int(end.timeIntervalSince(start)))
    }
}
