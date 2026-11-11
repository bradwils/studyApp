import Foundation

/// The kind and configuration stored for a custom field definition.
///
/// ## Declaration
///
/// ```swift
/// enum FieldKind: Codable
/// ```
/// Keeps each concrete configuration in an associated value so Codable can
/// encode and decode it, while callers access shared behavior through ``config``.
///
/// > Important: The associated configuration payloads change the encoded shape.
/// > Previously saved field kinds require migration or a data reset before loading.
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
