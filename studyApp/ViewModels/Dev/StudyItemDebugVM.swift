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
        // Batch deletion can fail on the values' inverse relationships instead of applying cascades.
        guard let items = try? context.fetch(FetchDescriptor<StudyItem>()) else { return }
        for item in items { context.delete(item) }
        try? context.save()
    }

    func touch(_ item: StudyItem) {
        item.updatedAt = .now
    }

    func setStatus(_ status: StudyItemStatus, on item: StudyItem) {
        guard item.status != status else { return }
        item.status = status
        item.completedAt = status == .completed ? .now : nil
        touch(item)
    }

    func setSubject(_ subject: Subject?, on item: StudyItem) {
        item.subject = subject
        item.subjectName = subject?.name
        touch(item)
    }

    func addValue(for definition: FieldDefinition, to item: StudyItem, context: ModelContext) {
        guard !item.values.contains(where: { $0.definition?.persistentModelID == definition.persistentModelID }) else { return }
        let value = FieldValue(content: definition.kind.config.defaultContent)
        context.insert(value)
        value.definition = definition
        value.item = item
        touch(item)
        try? context.save()
    }

    func setContent(_ content: FieldContent, on value: FieldValue) {
        value.content = content
        if let item = value.item { touch(item) }
    }

    func delete(_ value: FieldValue, from item: StudyItem, context: ModelContext) {
        context.delete(value)
        touch(item)
        try? context.save()
    }
}
