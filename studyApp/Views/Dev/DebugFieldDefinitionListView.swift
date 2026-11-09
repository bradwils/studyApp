//  DebugFieldDefinitionListView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Lists every field with an
//  enable toggle: the built-in item properties, then the custom FieldDefinitions
//  (create, edit via swipe, delete). Deleting one cascades to its FieldValues.

import SwiftUI
import SwiftData

struct DebugFieldDefinitionListView: View {
    @Query private var definitions: [FieldDefinition]
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
            }
        }
        .navigationTitle("Fields")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") { present(nil) }
            }
        }
        .sheet(isPresented: $isShowingForm) {
            DebugFieldDefinitionForm(vm: vm)
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
                    Picker("Kind", selection: $vm.kind) {
                        ForEach(FieldKind.allCases) { Label($0.rawValue.capitalized, systemImage: $0.systemImage).tag($0) }
                    }
                    .disabled(vm.isEditing)
                    if vm.kind == .dropdown {
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
                        vm.save(context: modelContext)
                        dismiss()
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
    }
}
