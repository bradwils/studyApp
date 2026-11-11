import Foundation
import SwiftData

enum FieldKindChoice: String, CaseIterable, Identifiable {
    case text, number, date, time, dropdown

    var id: String { rawValue }

    init(_ kind: FieldKind) {
        switch kind {
        case .text: self = .text
        case .number: self = .number
        case .date: self = .date
        case .time: self = .time
        case .dropdown: self = .dropdown
        }
    }

    var systemImage: String {
        switch self {
        case .text: "textformat"
        case .number: "number"
        case .date: "calendar"
        case .time: "clock"
        case .dropdown: "list.bullet"
        }
    }
}

@Observable
final class FieldDefinitionFormVM {
    var name = ""
    var choice: FieldKindChoice = .text
    var optionsText = ""
    var isEnabled = true

    private var editing: FieldDefinition?

    var isEditing: Bool { editing != nil }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (choice != .dropdown || !options.isEmpty)
    }

    private var options: [String] {
        optionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var kind: FieldKind {
        switch choice {
        case .text: .text(TextFieldConfig())
        case .number: .number(NumberFieldConfig())
        case .date: .date(DateFieldConfig())
        case .time: .time(TimeFieldConfig())
        case .dropdown: .dropdown(DropdownFieldConfig(options: options))
        }
    }

    func load(_ definition: FieldDefinition) {
        editing = definition
        name = definition.name
        choice = FieldKindChoice(definition.kind)
        isEnabled = definition.isEnabled
        if case .dropdown(let config) = definition.kind {
            optionsText = config.options.joined(separator: ", ")
        }
    }

    func save(nextOrder: Int, context: ModelContext) {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let editing {
            editing.name = trimmed
            editing.isEnabled = isEnabled
            // Kind is locked after creation so existing values can't mismatch their definition
            if choice == .dropdown { editing.kind = kind }
        } else {
            context.insert(FieldDefinition(name: trimmed, kind: kind, order: nextOrder, isEnabled: isEnabled))
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
