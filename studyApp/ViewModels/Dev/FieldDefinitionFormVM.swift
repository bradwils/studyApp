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

    func save(context: ModelContext) {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let editing {
            editing.name = trimmed
            editing.isEnabled = isEnabled
            // Kind is locked after creation so existing values can't mismatch their definition
            if editing.kind == .dropdown { editing.options = options }
        } else {
            context.insert(FieldDefinition(name: trimmed, kind: kind, options: kind == .dropdown ? options : [], isEnabled: isEnabled))
        }
        try? context.save()
    }

    func delete(_ definition: FieldDefinition, context: ModelContext) {
        context.delete(definition)
        try? context.save()
    }

}
