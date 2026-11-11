import Foundation


extension FieldConfig {
    var isValid: Bool { true }
}

struct TextFieldConfig: FieldConfig {
    var systemImage: String { "textformat" }
    var defaultContent: FieldContent { .text("") }
}

struct NumberFieldConfig: FieldConfig {
    var systemImage: String { "number" }
    var defaultContent: FieldContent { .number(0) }
}

struct DateFieldConfig: FieldConfig {
    var systemImage: String { "calendar" }
    var defaultContent: FieldContent { .date(.now) }
}

struct TimeFieldConfig: FieldConfig {
    var systemImage: String { "clock" }
    var defaultContent: FieldContent { .time(0) }
}

struct DropdownFieldConfig: FieldConfig {
    var options: [String]

    var systemImage: String { "list.bullet" }
    var defaultContent: FieldContent { .dropdown(options.first ?? "") }
    var isValid: Bool { !options.isEmpty }
}
