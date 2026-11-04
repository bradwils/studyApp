import Foundation

enum FieldKind: Codable {
    case text, number, date, time
    case dropdown(options: [String])

    var defaultContent: FieldContent {
        switch self {
        case .text: .text("")
        case .number: .number(0)
        case .date: .date(.now)
        case .time: .time(0)
        case .dropdown(let options): .dropdown(options.first ?? "")
        }
    }
}

enum FieldContent: Codable {
    case text(String)
    case number(Double)
    case date(Date)
    case time(TimeInterval)
    case dropdown(String)
}
