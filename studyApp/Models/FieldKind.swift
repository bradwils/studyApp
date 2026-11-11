import Foundation

// Codable needs one concrete stored type, so this enum names which config struct a definition holds.
enum FieldKind: Codable {
    case text(TextFieldConfig)
    case number(NumberFieldConfig)
    case date(DateFieldConfig)
    case time(TimeFieldConfig)
    case dropdown(DropdownFieldConfig)

    var config: any FieldConfig {
        switch self {
        case .text(let config): config
        case .number(let config): config
        case .date(let config): config
        case .time(let config): config
        case .dropdown(let config): config
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
