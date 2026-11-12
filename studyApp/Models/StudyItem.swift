import Foundation
import SwiftData

@Model
final class StudyItem {
    @Attribute(.unique) var id: UUID
    var taskName: String
    var notes: String?
    var status: StudyItemStatus
    var dueDate: Date?
    var priority: StudyItemPriority?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    @Relationship(deleteRule: .nullify)
    var subject: Subject?
    // Survives subject deletion, like StudySession
    var subjectName: String?

    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []

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

enum StudyItemStatus: String, Codable, CaseIterable {
    case notStarted, inProgress, completed, onHold
}

enum StudyItemPriority: String, Codable, CaseIterable {
    case low, medium, high
}
