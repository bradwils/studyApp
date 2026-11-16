import Foundation

struct SocialV4Mock: Decodable {
    let me: Me
    let session: Session
    let friends: [Friend]
    let suggestions: [Friend]

    struct Me: Decodable {
        let initials: String
        let todaySeconds: Int
        let weekSeconds: Int
        let goalSeconds: Int
        let streakDays: Int
    }

    struct Session: Decodable {
        let subjectName: String
        let subjectCode: String
        let withNames: [String]
        let elapsedSeconds: Int
    }

    struct Friend: Decodable, Identifiable, Hashable {
        let id: String
        let initials: String
        let name: String
        let firstName: String
        var status: ActiveStatus
        let subjectName: String?
        let subjectCode: String?
        let sessionSeconds: Int?
        let breakSeconds: Int?
        let todaySeconds: Int
        let weekSeconds: Int
        let goalSeconds: Int
        let lastSeen: String?
        let isMe: Bool?

        var isCurrentUser: Bool { isMe ?? false }
        var isLive: Bool { status == .studying }
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
}

enum V4Format {
    static func clock(_ seconds: Int) -> String {
        let total: Int = max(0, seconds)
        let pattern: Duration.TimeFormatStyle.Pattern = total >= 3600 ? .hourMinuteSecond : .minuteSecond
        return Duration.seconds(total).formatted(.time(pattern: pattern))
    }

    static func duration(_ seconds: Int) -> String {
        Duration.seconds(max(0, seconds)).formatted(
            .units(allowed: [.hours, .minutes], width: .narrow, fractionalPart: .hide(rounded: .down))
        )
    }
}
