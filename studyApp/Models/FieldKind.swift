import Foundation

// Payload-free discriminator: says which FieldValue slot is live. Dropdown options live on FieldDefinition.
enum FieldKind: String, Codable, CaseIterable, Identifiable {
    case text, number, date, time, dropdown

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .text: "textformat"
        case .number: "number"
        case .date: "calendar"
        case .time: "clock"
        case .dropdown: "list.bullet"
        }
    }
}
