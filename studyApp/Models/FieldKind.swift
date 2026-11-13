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
    /// The SF Symbol for this type, taken from its ``FieldConfig``.
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
    /// Free-form text.
    case text(TextFieldConfig)
    /// A numeric value.
    case number(NumberFieldConfig)
    /// A calendar date.
    case date(DateFieldConfig)
    /// A duration, stored in seconds.
    case time(TimeFieldConfig)
    /// One choice from a fixed list.
    case dropdown(DropdownFieldConfig)

    /// Creates the kind for a stored type, using default settings.
    ///
    /// - Parameters:
    ///   - type: The persisted field type.
    ///   - options: The dropdown choices; ignored for every other type.
    init(type: FieldType, options: [String]) {
        switch type {
        case .text: self = .text(TextFieldConfig())
        case .number: self = .number(NumberFieldConfig())
        case .date: self = .date(DateFieldConfig())
        case .time: self = .time(TimeFieldConfig())
        case .dropdown: self = .dropdown(DropdownFieldConfig(options: options))
        }
    }

    /// The persisted ``FieldType`` that corresponds to this case.
    var type: FieldType {
        switch self {
        case .text: .text
        case .number: .number
        case .date: .date
        case .time: .time
        case .dropdown: .dropdown
        }
    }

    /// The configuration wrapped by this case, for behavior that is the same across kinds.
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

/// The data held by a ``FieldValue``, with one case per ``FieldType``.
///
/// ## Declaration
///
/// ```swift
/// enum FieldContent: Codable
/// ```
///
/// Each case carries the payload its field type needs. ``FieldConfig/defaultContent``
/// supplies the starting case for a new value.
///
/// > Note: A dropdown stores the chosen option's text, not its index, so renaming or
/// > removing an option in ``FieldDefinition/options`` leaves existing values unchanged.
enum FieldContent: Codable {
    /// Free-form text.
    case text(String)
    /// A numeric value.
    case number(Double)
    /// A calendar date.
    case date(Date)
    /// A duration in seconds.
    case time(TimeInterval)
    /// The text of the selected option.
    case dropdown(String)
}
