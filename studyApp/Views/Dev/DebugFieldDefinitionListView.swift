//  DebugFieldDefinitionListView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Lists every field with an
//  enable toggle: the built-in item properties, then the custom FieldDefinitions
//  (create, edit via swipe, reorder, delete). Deleting one cascades to its FieldValues.

import SwiftUI
import SwiftData

struct DebugFieldDefinitionListView: View {
    @Query(sort: \FieldDefinition.order) private var definitions: [FieldDefinition]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = FieldDefinitionFormVM()
    @State private var isShowingForm = false

    var body: some View {
        List {
            Section {
                ForEach(BuiltInField.allCases) { BuiltInFieldToggleRow($0) }
            } header: {
                Text("Built-in")
            } footer: {
                Text("Disabled fields are hidden when editing an item. Their data is kept.")
            }
            Section("Custom") {
                if definitions.isEmpty {
                    ContentUnavailableView("No Custom Fields", systemImage: "list.bullet.rectangle", description: Text("Tap + to create one."))
                }
                ForEach(definitions) { definition in
                    DebugFieldDefinitionRow(definition: definition)
                        .swipeActions {
                            Button(role: .destructive) {
                                vm.delete(definition, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Edit", systemImage: "pencil") { present(definition) }
                        }
                }
                .onMove { vm.move(definitions, from: $0, to: $1, context: modelContext) }
            }
        }
        .navigationTitle("Fields")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") { present(nil) }
            }
        }
        .sheet(isPresented: $isShowingForm) {
            DebugFieldDefinitionForm(vm: vm, nextOrder: (definitions.map(\.order).max() ?? -1) + 1)
                .presentationDetents([.medium, .large])
        }
    }

    private func present(_ definition: FieldDefinition?) {
        vm = FieldDefinitionFormVM()
        if let definition { vm.load(definition) }
        isShowingForm = true
    }
}

private struct DebugFieldDefinitionForm: View {
    @Bindable var vm: FieldDefinitionFormVM
    let nextOrder: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $vm.name)
                    Toggle("Enabled", isOn: $vm.isEnabled)
                }
                Section {
                    Picker("Kind", selection: $vm.choice) {
                        ForEach(FieldType.allCases) { Label($0.rawValue.capitalized, systemImage: $0.systemImage).tag($0) }
                    }
                    .disabled(vm.isEditing)
                    if vm.choice == .dropdown {
                        TextField("Options, comma separated", text: $vm.optionsText)
                    }
                } footer: {
                    if vm.isEditing { Text("Kind is locked once created.") }
                }
            }
            .navigationTitle(vm.isEditing ? "Edit Field" : "New Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.save(nextOrder: nextOrder, context: modelContext)
                        dismiss()
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
    }
}
