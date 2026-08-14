//  TaskRowView.swift
//  studyApp
//
//  One row in a task board: the title as the headline, plus the columns the layout
//  marked showInRow — everything else stays detail-only.
//
//  The done control is deliberately NOT here. This view is used as a NavigationLink
//  label, and a Button inside a link label never receives its own taps in a List — the
//  link swallows them. TaskDoneToggle below is placed as the link's sibling instead.

import SwiftUI
import SwiftData

struct TaskRowView: View {
    let task: StudyTask
    let columns: [TaskFieldDefinition]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText
            if !rowColumns.isEmpty {
                fieldCellRow
            }
        }
        .padding(.vertical, 2)
    }

    // Title is already the headline above, and Done already has the toggle to its left —
    // showing either again as a generic cell would just repeat what's already on screen.
    private var rowColumns: [TaskFieldDefinition] {
        columns.filter { $0.showInRow && $0.coreKey != .title && $0.coreKey != .isDone }
    }

    private var titleText: some View {
        Text(task.title.isEmpty ? "Untitled" : task.title)
            .font(.headline)
            .strikethrough(task.isDone)
            .foregroundStyle(task.isDone ? .secondary : .primary)
    }

    private var fieldCellRow: some View {
        HStack(spacing: 8) {
            ForEach(rowColumns, id: \.persistentModelID) { column in
                TaskFieldCell(column: column, content: task.content(for: column))
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// Sibling of the NavigationLink rather than part of its label, so tapping the circle
// completes the task instead of pushing the detail screen.
struct TaskDoneToggle: View {
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isDone ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? "Mark as not done" : "Mark as done")
    }
}

#Preview {
    let layout = TaskBoardLayout.makeDefault()
    let task = StudyTask(title: "Read chapter 4", dueDate: .now.addingTimeInterval(86_400))

    List {
        HStack(alignment: .top, spacing: 12) {
            TaskDoneToggle(isDone: task.isDone) {}
            TaskRowView(task: task, columns: TaskSeeding.orderedColumns(of: layout))
        }
    }
    .modelContainer(for: TaskSchema.models, inMemory: true)
}
