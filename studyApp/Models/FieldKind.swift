import Foundation

/// The kind of a custom field, persisted as a plain string.
///
/// ## Declaration
///
/// ```swift
/// enum FieldType: String, Codable, CaseIterable, Identifiable
/// ```
///
/// ``FieldDefinition`` stores this raw value in its `type` column. Use
/// ``FieldKind/init(type:options:)`` to get the matching runtime configuration.
enum FieldType: String, Codable, CaseIterable, Identifiable {
    case text, number, date, time, dropdown

    var id: String { rawValue }
    var systemImage: String { FieldKind(type: self, options: []).config.systemImage }
}

/// The runtime kind of a custom field, pairing each ``FieldType`` with its configuration.
///
/// ## Declaration
///
/// ```swift
/// enum FieldKind: Codable
/// ```
///
/// Use ``config`` for behavior shared across kinds and ``type`` for the matching ``FieldType``.
///
/// > Important: FieldKind is never persisted. ``FieldDefinition`` stores `type` and `options`
/// > and rebuilds this value, because SwiftData crashes when it persists enums with struct payloads.
enum FieldKind: Codable {
    case text(TextFieldConfig)
    case number(NumberFieldConfig)
    case date(DateFieldConfig)
    case time(TimeFieldConfig)
    case dropdown(DropdownFieldConfig)

    init(type: FieldType, options: [String]) {
        switch type {
        case .text: self = .text(TextFieldConfig())
        case .number: self = .number(NumberFieldConfig())
        case .date: self = .date(DateFieldConfig())
        case .time: self = .time(TimeFieldConfig())
        case .dropdown: self = .dropdown(DropdownFieldConfig(options: options))
        }
    }

    var type: FieldType {
        switch self {
        case .text: .text
        case .number: .number
        case .date: .date
        case .time: .time
        case .dropdown: .dropdown
        }
    }

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
