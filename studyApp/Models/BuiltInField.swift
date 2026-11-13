import Foundation

/// The optional properties every study item has natively, which can each be hidden.
///
/// ## Declaration
///
/// ```swift
/// enum BuiltInField: String, CaseIterable, Identifiable
/// ```
///
/// Whether a field is shown is a per-device setting kept in `UserDefaults`, not on the
/// model. The task name and subject are not listed here because they are always shown.
///
/// ```swift
/// @AppStorage(BuiltInField.notes.storageKey) private var showsNotes = true
/// ```
///
/// > Note: Hiding a field only hides it in the UI; the item keeps its stored data.
enum BuiltInField: String, CaseIterable, Identifiable {
    /// Each case matches the ``StudyItem`` property of the same name; `tag` maps to ``StudyItem/tags``.
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

    /// The `UserDefaults` / `AppStorage` key for this field's enabled toggle.
    ///
    /// Every reader declares the storage with a default of `true`, so a field is enabled until turned off.
    var storageKey: String { "itemField.\(rawValue).isEnabled" }
}
