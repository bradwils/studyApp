import Foundation
import SwiftData

@Observable
final class FieldDefinitionFormVM {
    var name = ""
    var kind: FieldKind = .text
    var optionsText = ""
    var isEnabled = true

    private var editing: FieldDefinition?

    var isEditing: Bool { editing != nil }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (kind != .dropdown || !options.isEmpty)
    }

    private var options: [String] {
        optionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func load(_ definition: FieldDefinition) {
        editing = definition
        name = definition.name
        kind = definition.kind
        isEnabled = definition.isEnabled
        optionsText = definition.options.joined(separator: ", ")
    }

    func save(nextOrder: Int, context: ModelContext) {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let editing {
            editing.name = trimmed
            editing.isEnabled = isEnabled
            // Kind is locked after creation so existing values can't mismatch their definition
            if editing.kind == .dropdown { editing.options = options }
        } else {
            context.insert(FieldDefinition(name: trimmed, kind: kind, options: kind == .dropdown ? options : [], order: nextOrder, isEnabled: isEnabled))
        }
        try? context.save()
    }

    func delete(_ definition: FieldDefinition, context: ModelContext) {
        context.delete(definition)
        try? context.save()
    }

    func move(_ definitions: [FieldDefinition], from source: IndexSet, to destination: Int, context: ModelContext) {
        var reordered = definitions
        // Array.move(fromOffsets:) lives in SwiftUI, which ViewModels can't import
        let moving = source.map { reordered[$0] }
        let insertAt = destination - source.filter { $0 < destination }.count
        for index in source.reversed() { reordered.remove(at: index) }
        reordered.insert(contentsOf: moving, at: insertAt)
        for (index, definition) in reordered.enumerated() {
            definition.order = index
        }
        try? context.save()
    }
}
