import Foundation
import SwiftData

@Observable
final class TagDebugVM {
    var newName = ""
    var newColor: TagColor = .blue

    func canAdd(existing: [Tag]) -> Bool {
        let key = Tag.key(for: newName.trimmingCharacters(in: .whitespacesAndNewlines))
        return !key.isEmpty && !existing.contains { $0.key == key }
    }

    func addTag(existing: [Tag], context: ModelContext) {
        guard canAdd(existing: existing) else { return }
        context.insert(Tag(name: newName, color: newColor))
        try? context.save()
        newName = ""
    }

    func delete(_ tag: Tag, context: ModelContext) {
        context.delete(tag)
        try? context.save()
    }
}
