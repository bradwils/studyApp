import Foundation

extension StudySession {
    /// The zone the session started in, or `fallback` when ``timeZoneID`` is missing or unrecognised.
    func timeZone(fallback: TimeZone = .current) -> TimeZone {
        timeZoneID.flatMap { TimeZone(identifier: $0) } ?? fallback
    }
}
