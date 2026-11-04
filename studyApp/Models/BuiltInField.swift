import Foundation

/// Properties every study item has natively. Each can be hidden from item screens;
/// the task name and subject are always shown.
enum BuiltInField: String, CaseIterable, Identifiable {
    case notes, status, priority, dueDate, tag

    var id: Self { self }

    var title: String {
        switch self {
        case .notes: "Notes"
        case .status: "Status"
        case .priority: "Priority"
        case .dueDate: "Due date"
        case .tag: "Tag"
        }
    }

    var systemImage: String {
        switch self {
        case .notes: "note.text"
        case .status: "circle.dotted"
        case .priority: "exclamationmark.triangle"
        case .dueDate: "calendar"
        case .tag: "tag"
        }
    }

    var storageKey: String { "itemField.\(rawValue).isEnabled" }
}
