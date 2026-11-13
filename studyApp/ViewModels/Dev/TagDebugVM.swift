import Foundation
import SwiftData

@Observable
final class TagDebugVM {
    var newName = ""
    var newColor: TagColor = .gray

    var canAdd: Bool {
        !Tag.key(for: newName).isEmpty
    }

    func addTag(context: ModelContext) {
        guard canAdd else { return }
        resolveTag(named: newName, color: newColor, context: context)
        newName = ""
    }

    /// Returns the tag for `name`, creating it with `color` only if no tag with that key exists.
    @discardableResult
    func resolveTag(named name: String, color: TagColor, context: ModelContext) -> Tag? {
        let key = Tag.key(for: name)
        guard !key.isEmpty else { return nil }

        // `.unique` upserts, so an insert would overwrite the oldest tag; look it up first instead
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            duplicateTagDetected(existing)
            return existing
        }

        let tag = Tag(name: name, color: color)
        context.insert(tag)
        try? context.save()
        return tag
    }

    /// Called when a requested tag already exists and was reused instead of created.
    func duplicateTagDetected(_ existing: Tag) {
        // A "Duplicate tag detected" toast will be shown here later
    }

    func delete(_ tag: Tag, context: ModelContext) {
        context.delete(tag)
        try? context.save()
    }
}
