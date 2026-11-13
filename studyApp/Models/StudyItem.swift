import Foundation
import SwiftData

/// A task or assignment to complete, optionally tied to a subject.
///
/// ## Declaration
///
/// ```swift
/// @Model final class StudyItem
/// ```
///
/// Built-in properties cover the common fields. User-defined fields are stored as
/// ``FieldValue`` rows in ``values``, each linked to its ``FieldDefinition``.
///
/// ```swift
/// let item = StudyItem(taskName: "Read chapter 4", subject: maths, priority: .high)
/// context.insert(item)
/// ```
///
/// > Important: Callers maintain `completedAt` and `updatedAt` when editing.
/// > The developer editor routes status and content changes through `StudyItemDebugVM`.
@Model
final class StudyItem {
    @Attribute(.unique) var id: UUID
    var taskName: String
    var notes: String?
    var status: StudyItemStatus
    var dueDate: Date?
    var priority: StudyItemPriority?
    var createdAt: Date
    /// When the item was last edited; callers must set it, nothing updates it automatically.
    var updatedAt: Date
    /// When the item was completed, or `nil` if it has not been.
    var completedAt: Date?
    /// The subject this item belongs to, or `nil` once the subject is deleted.
    @Relationship(deleteRule: .nullify)
    var subject: Subject?
    /// The subject's name, copied at creation so it survives deletion of the subject.
    ///
    /// Callers must refresh it when reassigning ``subject``.
    var subjectName: String?

    /// Labels on this item. Deleting the item detaches it from its tags; the tags are kept.
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []

    /// Values for the user-defined fields. Deleting the item deletes these values.
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.item)
    var values: [FieldValue] = []

    init(
        taskName: String,
        subject: Subject? = nil,
        notes: String? = nil,
		status: StudyItemStatus = .notStarted,
        dueDate: Date? = nil,
        priority: StudyItemPriority? = nil
    ) {
        self.id = UUID()
        self.taskName = taskName
        self.subject = subject
        self.subjectName = subject?.name
        self.notes = notes
        self.status = status
        self.dueDate = dueDate
        self.priority = priority
        self.createdAt = .now
        self.updatedAt = .now
        self.completedAt = status == .completed ? .now : nil
    }
}

/// Where a study item is in its lifecycle.
///
/// ## Declaration
///
/// ```swift
/// enum StudyItemStatus: String, Codable, CaseIterable
/// ```
enum StudyItemStatus: String, Codable, CaseIterable {
    case notStarted, inProgress, completed, onHold
}

/// How urgent a study item is; an item with no priority stores `nil`.
///
/// ## Declaration
///
/// ```swift
/// enum StudyItemPriority: String, Codable, CaseIterable
/// ```
enum StudyItemPriority: String, Codable, CaseIterable {
    case low, medium, high
}
