import Foundation

struct SocialV4Mock: Decodable {
    let me: Me
    let session: Session
    let friends: [Friend]

    struct Me: Decodable {
        let initials: String
        let todaySeconds: Int
        let goalSeconds: Int
        let streakDays: Int
    }

    struct Session: Decodable {
        let subjectName: String
        let subjectCode: String
        let withNames: [String]
        let elapsedSeconds: Int
    }

    struct Friend: Decodable, Identifiable {
        let id: String
        let initials: String
        let name: String
        let firstName: String
        let status: ActiveStatus
        let subjectName: String?
        let subjectCode: String?
        let sessionSeconds: Int?
        let breakSeconds: Int?
        let todaySeconds: Int
        let goalSeconds: Int
        let lastSeen: String?
        let isMe: Bool?

        var isCurrentUser: Bool { isMe ?? false }
        var isLive: Bool { status == .studying || status == .online }
    }

    static func load(from bundle: Bundle = .main) -> SocialV4Mock {
        let fileName = "SocialV4MockData"
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            fatalError("SocialV4MockData.json is missing from the app bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SocialV4Mock.self, from: data)
        } catch {
            fatalError("SocialV4MockData.json could not be decoded: \(error)")
        }
    }

    var stripFriends: [Friend] {
        let others = friends.filter { !$0.isCurrentUser }
        let live = others
            .filter { $0.isLive }
            .sorted { ($0.sessionSeconds ?? 0) > ($1.sessionSeconds ?? 0) }
        let paused = others.filter { $0.status == .paused }
        return live + paused
    }

    var listFriends: [Friend] {
        friends.sorted { $0.todaySeconds > $1.todaySeconds }
    }

    var friendCount: Int {
        friends.filter { !$0.isCurrentUser }.count
    }
}

enum V4Format {
    static func clock(_ seconds: Int) -> String {
        let total: Int = max(0, seconds)
        let hours: Int = total / 3600
        let minutes: Int = (total % 3600) / 60
        let secs: Int = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    static func duration(_ seconds: Int) -> String {
        let total: Int = max(0, seconds)
        let hours: Int = total / 3600
        let minutes: Int = (total % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return "\(minutes)m"
    }
}
