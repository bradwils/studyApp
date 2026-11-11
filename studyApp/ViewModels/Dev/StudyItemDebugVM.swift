import Foundation
import SwiftData

@Observable
final class StudyItemDebugVM {
    func addItem(context: ModelContext) -> StudyItem {
        let item = StudyItem(taskName: "New item")
        context.insert(item)
        try? context.save()
        return item
    }

    func delete(_ item: StudyItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    func deleteAll(context: ModelContext) {
        try? context.delete(model: StudyItem.self)
        try? context.save()
    }

    func touch(_ item: StudyItem) {
        item.updatedAt = .now
    }

    func setStatus(_ status: StudyItemStatus, on item: StudyItem) {
        item.status = status
        // TODO(human): decide how completedAt follows status changes
        touch(item)
    }

    func setSubject(_ subject: Subject?, on item: StudyItem) {
        item.subject = subject
        item.subjectName = subject?.name
        touch(item)
    }

    func addValue(for definition: FieldDefinition, to item: StudyItem, context: ModelContext) {
        let value = FieldValue(content: definition.kind.config.defaultContent)
        context.insert(value)
        value.definition = definition
        value.item = item
        touch(item)
        try? context.save()
    }

    func delete(_ value: FieldValue, from item: StudyItem, context: ModelContext) {
        context.delete(value)
        touch(item)
        try? context.save()
    }
}
