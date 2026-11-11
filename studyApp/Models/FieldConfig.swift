import Foundation


extension FieldConfig {
    var isValid: Bool { true }
}

/// Configuration for a custom text field, initially empty.
///
/// ## Declaration
///
/// ```swift
/// struct TextFieldConfig: FieldConfig
/// ```
struct TextFieldConfig: FieldConfig {
    var systemImage: String { "textformat" }
    var defaultContent: FieldContent { .text("") }
}

/// Configuration for a custom numeric field, initially zero.
///
/// ## Declaration
///
/// ```swift
/// struct NumberFieldConfig: FieldConfig
/// ```
struct NumberFieldConfig: FieldConfig {
    var systemImage: String { "number" }
    var defaultContent: FieldContent { .number(0) }
}

/// Configuration for a custom date field, initially set to the current date.
///
/// ## Declaration
///
/// ```swift
/// struct DateFieldConfig: FieldConfig
/// ```
struct DateFieldConfig: FieldConfig {
    var systemImage: String { "calendar" }
    /// Captures the current date on each access, rather than when the configuration is created.
    var defaultContent: FieldContent { .date(.now) }
}

/// Configuration for a custom time field, initially zero.
///
/// ## Declaration
///
/// ```swift
/// struct TimeFieldConfig: FieldConfig
/// ```
struct TimeFieldConfig: FieldConfig {
    var systemImage: String { "clock" }
    var defaultContent: FieldContent { .time(0) }
}

/// Configuration for a custom dropdown field with ordered choices.
///
/// ## Declaration
///
/// ```swift
/// struct DropdownFieldConfig: FieldConfig
/// ```
/// The first option supplies the initial selection. An empty options array is
/// invalid, but still produces an empty-string selection if its default is read.
struct DropdownFieldConfig: FieldConfig {
    var options: [String]

    var systemImage: String { "list.bullet" }
    var defaultContent: FieldContent { .dropdown(options.first ?? "") }
    var isValid: Bool { !options.isEmpty }
}
