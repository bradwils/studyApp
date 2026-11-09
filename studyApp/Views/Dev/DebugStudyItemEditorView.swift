//  DebugStudyItemEditorView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Edits write straight to the
//  model, so there is no save button.

import SwiftUI
import SwiftData

struct DebugStudyItemEditorView: View {
    @Bindable var item: StudyItem

    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query private var definitions: [FieldDefinition]
    @Query(sort: \Tag.key) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = StudyItemDebugVM()

    private var visibleValues: [FieldValue] {
        item.values
            .filter { $0.definition?.isEnabled ?? true }
    }

    private var unusedDefinitions: [FieldDefinition] {
        let used = Set(item.values.compactMap { $0.definition?.persistentModelID })
        return definitions.filter { $0.isEnabled && !used.contains($0.persistentModelID) }
    }

    var body: some View {
        Form {
            basicsSection
            planningSection
            fieldsSection
            metadataSection
        }
        .navigationTitle(item.taskName.isEmpty ? "Study Item" : item.taskName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: item.taskName) { vm.touch(item) }
        .onChange(of: item.notes) { vm.touch(item) }
        .onChange(of: item.priority) { vm.touch(item) }
        .onChange(of: item.tag) { vm.touch(item) }
        .onChange(of: item.dueDate) { vm.touch(item) }
    }

    private var basicsSection: some View {
        Section("Basics") {
            TextField("Task name", text: $item.taskName)
            BuiltInFieldGate(.notes) {
                TextField("Notes", text: notesBinding, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
    }

    private var planningSection: some View {
        Section("Planning") {
            BuiltInFieldGate(.status) {
                Picker("Status", selection: statusBinding) {
                    ForEach(StudyItemStatus.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }
            BuiltInFieldGate(.priority) {
                Picker("Priority", selection: $item.priority) {
                    Text("None").tag(StudyItemPriority?.none)
                    ForEach(StudyItemPriority.allCases, id: \.self) { Text($0.rawValue.capitalized).tag(StudyItemPriority?.some($0)) }
                }
            }
            BuiltInFieldGate(.tag) {
                Picker("Tag", selection: $item.tag) {
                    Text("None").tag(Tag?.none)
                    ForEach(tags) { Text($0.key).tag(Tag?.some($0)) }
                }
            }
            Picker("Subject", selection: subjectBinding) {
                Text("None").tag(Subject?.none)
                ForEach(subjects) { Text("\($0.name) (\($0.code))").tag(Subject?.some($0)) }
            }
            BuiltInFieldGate(.dueDate) {
                Toggle("Due date", isOn: hasDueDateBinding)
                if let due = item.dueDate {
                    DatePicker("Due", selection: Binding(get: { due }, set: { item.dueDate = $0 }))
                }
            }
        }
    }

    private var fieldsSection: some View {
        Section {
            ForEach(visibleValues) { value in
                DebugFieldValueRow(value: value)
            }
            .onDelete { offsets in
                let values = visibleValues
                for index in offsets { vm.delete(values[index], from: item, context: modelContext) }
            }
            Menu("Add field", systemImage: "plus.circle") {
                ForEach(unusedDefinitions) { definition in
                    Button(definition.name, systemImage: definition.kind.systemImage) {
                        vm.addValue(for: definition, to: item, context: modelContext)
                    }
                }
            }
            .disabled(unusedDefinitions.isEmpty)
        } header: {
            Text("Fields")
        } footer: {
            if definitions.isEmpty { Text("Create field definitions from the Debug Data screen first.") }
        }
    }

    private var metadataSection: some View {
        Section("Metadata") {
            LabeledContent("ID", value: item.id.uuidString.prefix(8) + "…")
            LabeledContent("Created", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Updated", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Completed", value: item.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
            LabeledContent("Subject name", value: item.subjectName ?? "—")
        }
        .foregroundStyle(.secondary)
    }

    private var notesBinding: Binding<String> {
        Binding(get: { item.notes ?? "" }, set: { item.notes = $0.isEmpty ? nil : $0 })
    }

    private var statusBinding: Binding<StudyItemStatus> {
        Binding(get: { item.status }, set: { vm.setStatus($0, on: item) })
    }

    private var subjectBinding: Binding<Subject?> {
        Binding(get: { item.subject }, set: { vm.setSubject($0, on: item) })
    }

    private var hasDueDateBinding: Binding<Bool> {
        Binding(get: { item.dueDate != nil }, set: { item.dueDate = $0 ? .now : nil })
    }
}

private struct DebugFieldValueRow: View {
    let value: FieldValue

    private var title: String { value.definition?.name ?? "Orphaned field" }

    var body: some View {
        switch value.definition?.kind {
        case .text:
            LabeledContent(title) {
                TextField("Text", text: Binding(get: { value.textValue ?? "" }, set: { value.textValue = $0 }))
                    .multilineTextAlignment(.trailing)
            }
        case .number:
            LabeledContent(title) {
                TextField("0", value: Binding(get: { value.numberValue ?? 0 }, set: { value.numberValue = $0 }), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        case .date:
            DatePicker(title, selection: Binding(get: { value.dateValue ?? .now }, set: { value.dateValue = $0 }))
        case .time:
            let seconds = value.timeValue ?? 0
            Stepper(
                "\(title): \(Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))",
                value: Binding(get: { seconds }, set: { value.timeValue = $0 }),
                in: 0...36_000,
                step: 300
            )
        case .dropdown:
            let selection = value.textValue ?? ""
            Picker(title, selection: Binding(get: { selection }, set: { value.textValue = $0 })) {
                ForEach(options(including: selection), id: \.self) { Text($0.isEmpty ? "—" : $0).tag($0) }
            }
        case nil:
            LabeledContent(title) { Text("No definition").foregroundStyle(.secondary) }
        }
    }

    // Keeps a stale selection visible if its option was later removed from the definition
    private func options(including selection: String) -> [String] {
        let options = value.definition?.options ?? []
        return options.contains(selection) ? options : [selection] + options
    }
}
