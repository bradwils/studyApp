//  DebugStudyItemListView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Create, open and delete
//  StudyItems; the editor shows every property and field value.

import SwiftUI
import SwiftData

struct DebugStudyItemListView: View {
    @Query(sort: \StudyItem.createdAt, order: .reverse) private var items: [StudyItem]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = StudyItemDebugVM()
    @State private var newItem: StudyItem?
    @State private var isShowingDeleteAllConfirmation = false

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("No Study Items", systemImage: "checklist", description: Text("Tap + to create one."))
            }
            ForEach(items) { item in
                NavigationLink { DebugStudyItemEditorView(item: item) } label: { row(for: item) }
                    .swipeActions {
                        Button(role: .destructive) {
                            vm.delete(item, context: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Study Items")
        .navigationDestination(item: $newItem) { DebugStudyItemEditorView(item: $0) }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Delete All", systemImage: "trash", role: .destructive) {
                    isShowingDeleteAllConfirmation = true
                }
                .disabled(items.isEmpty)
                Button("Add", systemImage: "plus") {
                    newItem = vm.addItem(context: modelContext)
                }
            }
        }
        .confirmationDialog(
            "Delete all \(items.count) study items?",
            isPresented: $isShowingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Study Items", role: .destructive) {
                vm.deleteAll(context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also deletes each item's field values. Subjects, field definitions and tags are kept.")
        }
    }

    private func row(for item: StudyItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.taskName.isEmpty ? "Untitled" : item.taskName).font(.headline)
                Spacer()
                Text(item.status.displayName)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.status.tint.opacity(0.15), in: .capsule)
                    .foregroundStyle(item.status.tint)
            }
            HStack(spacing: 6) {
                if let name = item.subjectName { Text(name) }
                if let priority = item.priority { Text("· \(priority.rawValue.capitalized)") }
                if let due = item.dueDate { Text("· due \(due.formatted(date: .abbreviated, time: .omitted))") }
                if !item.values.isEmpty { Text("· \(item.values.count) field(s)") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

extension StudyItemStatus {
    var displayName: String {
        switch self {
        case .notStarted: "Not started"
        case .inProgress: "In progress"
        case .completed: "Completed"
        case .onHold: "On hold"
        }
    }

    var tint: Color {
        switch self {
        case .notStarted: .gray
        case .inProgress: .blue
        case .completed: .green
        case .onHold: .orange
        }
    }
}

#Preview {
    NavigationStack { DebugStudyItemListView() }
        .modelContainer(
            for: [StudyItem.self, Subject.self, FieldDefinition.self, FieldValue.self, Tag.self],
            inMemory: true
        )
}
