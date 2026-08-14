//  TaskDetailView.swift
//  studyApp
//
//  Every column in the board's layout, in order, each editable through the shared
//  TaskFieldEditor widget — that widget writes through the §4 accessor seam itself,
//  so this view stays a plain layout of editors plus a delete action.

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: StudyTask
    let columns: [TaskFieldDefinition]

    @State private var vm = TaskEditorVM()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(columns, id: \.persistentModelID) { column in
                    TaskFieldEditor(column: column, task: task)
                }
            }

            if !vm.isTitleValid(task) {
                Section {
                    Label("Title is required", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(task.title.isEmpty ? "Task" : task.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete", role: .destructive) {
                    vm.isShowingDeleteConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: $vm.isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                vm.deleteTask(task, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}

#Preview {
    let layout = TaskBoardLayout.makeDefault()
    let task = StudyTask(title: "Create a data dictionary", dueDate: .now.addingTimeInterval(172_800))

    NavigationStack {
        TaskDetailView(task: task, columns: TaskSeeding.orderedColumns(of: layout))
    }
    .modelContainer(for: TaskSchema.models, inMemory: true)
}
