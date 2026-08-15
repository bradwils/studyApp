//  DebugTaskDataView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Inspects the Tasks module's
//  storage seam (docs/StudyTasks.md §4): for every task, shows each column's
//  resolved content next to the raw slot it was actually read from, so a value
//  written to the wrong TaskFieldValue slot is visible instead of quietly
//  rendering "correctly" through content(for:).

import SwiftUI
import SwiftData

struct DebugTaskDataView: View {
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @Query(sort: \TaskBoardLayout.name) private var layouts: [TaskBoardLayout]
    @Query private var boards: [SubjectTaskBoard]
    @Query private var fieldValues: [TaskFieldValue]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @Environment(\.modelContext) private var modelContext
    @State private var isShowingDeleteAllConfirmation = false

    var body: some View {
        List {
            sampleDataSection
            tasksSection
            layoutsSection
            boardsSection
            orphanedValuesSection
        }
        .navigationTitle("Task Data")
        .confirmationDialog(
            "Delete all task board data?",
            isPresented: $isShowingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) { deleteAllTaskData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes every StudyTask, TaskFieldValue, TaskFieldDefinition, TaskFieldOption, TaskBoardLayout, and SubjectTaskBoard row. This can't be undone.")
        }
    }

    // MARK: - Sample data controls

    private var sampleDataSection: some View {
        Section {
            Button {
                TaskSeeding.ensureDefaultLayout(in: modelContext)
            } label: {
                Label("Seed Default Layout", systemImage: "square.grid.2x2")
            }

            Button {
                generateSampleTask()
            } label: {
                Label("Generate Sample Task", systemImage: "wand.and.stars")
            }
            .disabled(subjects.isEmpty)

            Button(role: .destructive) {
                isShowingDeleteAllConfirmation = true
            } label: {
                Label("Delete All Task Data", systemImage: "trash")
            }
            .disabled(tasks.isEmpty && layouts.isEmpty && boards.isEmpty && fieldValues.isEmpty)
        } header: {
            Text("Sample Data")
        } footer: {
            if subjects.isEmpty {
                Text("Generate Sample Task is disabled — no Subject exists yet. Add one from Settings → Edit Subjects first.")
            } else {
                Text("Generate Sample Task fills every column the resolved layout actually defines, not a fixed set — see the Board Layouts section below for what that currently includes.")
            }
        }
    }

    private func generateSampleTask() {
        guard let subject = subjects.first,
              let board = TaskSeeding.board(for: subject, in: modelContext) else { return }

        let task = StudyTask(subject: subject, subjectName: subject.name)
        modelContext.insert(task)

        // Walks the resolved layout instead of hardcoding column names, so the button stays
        // correct if Default's columns change or the subject is bound to a custom layout.
        for column in TaskSeeding.orderedColumns(of: board.layout) {
            task.setContent(sampleContent(for: column), for: column, context: modelContext)
        }

        try? modelContext.save()
    }

    private func sampleContent(for column: TaskFieldDefinition) -> TaskFieldContent {
        if let coreKey = column.coreKey {
            switch coreKey {
            case .title:
                return .text("Create a data dictionary for tutorial 3")
            case .dueDate:
                return .date(Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
            case .isDone:
                return .flag(false)
            }
        }

        switch column.kind {
        case .text:
            return .text("Check the rubric for required fields before submitting.")
        case .date:
            return .date(Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now)
        case .checkbox:
            return .flag(false)
        case .select:
            guard let option = preferredOption(in: column) else { return .empty }
            return .options([option])
        case .multiSelect:
            let picked = (column.options ?? []).sorted { $0.sortIndex < $1.sortIndex }.prefix(2)
            return picked.isEmpty ? .empty : .options(Array(picked))
        case .number:
            return .number(10)
        case .scale:
            return .number((column.scaleMin + column.scaleMax) / 2)
        }
    }

    // The seeded Default layout's option ordering happens to put the plausible "doing it"
    // choice ("In progress", "Canvas") at index 1, so a sample task doesn't land on every
    // select column's blank-looking first option.
    private func preferredOption(in column: TaskFieldDefinition) -> TaskFieldOption? {
        let sorted = (column.options ?? []).sorted { $0.sortIndex < $1.sortIndex }
        guard !sorted.isEmpty else { return nil }
        return sorted.count > 1 ? sorted[1] : sorted[0]
    }

    private func deleteAllTaskData() {
        try? modelContext.delete(model: StudyTask.self)
        try? modelContext.delete(model: TaskFieldValue.self)
        try? modelContext.delete(model: TaskFieldDefinition.self)
        try? modelContext.delete(model: TaskFieldOption.self)
        try? modelContext.delete(model: TaskBoardLayout.self)
        try? modelContext.delete(model: SubjectTaskBoard.self)
        try? modelContext.save()
    }

    // MARK: - Tasks × columns (the main inspector)

    private var tasksSection: some View {
        Section {
            if tasks.isEmpty {
                ContentUnavailableView("No Tasks", systemImage: "checklist")
            } else {
                ForEach(tasks, id: \.persistentModelID) { task in
                    DisclosureGroup {
                        TaskColumnBreakdown(task: task, board: board(for: task))
                    } label: {
                        taskSummaryLabel(task)
                    }
                }
            }
        } header: {
            Text("Tasks × Columns")
        } footer: {
            Text("Expand a task to see every column's content(for:) result next to the raw storage it came from. Red text marks a TaskFieldValue whose populated slot doesn't match its column's kind, or that has more than one slot populated — the corruption states the seam in StudyTask+Fields.swift exists to prevent.")
        }
    }

    private func taskSummaryLabel(_ task: StudyTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title.isEmpty ? "Untitled" : task.title).font(.headline)
            Text("\(task.subjectName ?? "No subject") · \(task.isDone ? "Done" : "Open")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // Boards are keyed by subject, not by task, so this is the same lookup
    // TaskSeeding.board(for:in:) does — kept in memory rather than a #Predicate for the
    // same reason: matching on an optional relationship's id predicates handle badly.
    private func board(for task: StudyTask) -> SubjectTaskBoard? {
        guard let subjectID = task.subject?.id else { return nil }
        return boards.first { $0.subject?.id == subjectID }
    }

    // MARK: - Board layouts

    private var layoutsSection: some View {
        Section {
            if layouts.isEmpty {
                ContentUnavailableView("No Layouts", systemImage: "square.grid.2x2")
            } else {
                ForEach(layouts, id: \.persistentModelID) { layout in
                    DisclosureGroup {
                        ForEach(TaskSeeding.orderedColumns(of: layout), id: \.persistentModelID) { column in
                            LayoutColumnRow(column: column)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(layout.name.isEmpty ? "Untitled layout" : layout.name).font(.headline)
                            Text("\(layout.isDefault ? "Default · " : "")\((layout.columns ?? []).count) column(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Board Layouts")
        }
    }

    // MARK: - Subject → layout bindings

    private var boardsSection: some View {
        Section {
            if boards.isEmpty {
                ContentUnavailableView("No Bindings", systemImage: "link")
            } else {
                ForEach(boards, id: \.persistentModelID) { board in
                    HStack(spacing: 6) {
                        Text(board.subject?.name ?? "<nil subject>")
                            .foregroundStyle(board.subject == nil ? .red : .primary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                        Text(board.layout?.name ?? "<nil layout>")
                            .foregroundStyle(board.layout == nil ? .red : .primary)
                    }
                    .font(.subheadline)
                }
            }
        } header: {
            Text("Subject → Layout Bindings")
        } footer: {
            Text("Red entries are dangling references (docs/StudyTasks.md §10) — nullify delete rules leave the binding row in place when the subject or layout it pointed at is deleted.")
        }
    }

    // MARK: - Orphaned TaskFieldValue rows

    private var orphanedValuesSection: some View {
        // Ground truth for "still belongs to a layout" is the layouts' own column lists,
        // not TaskFieldDefinition.layout — a detached-but-undeleted definition is exactly
        // the state this check exists to catch, so it shouldn't lean on the same inverse
        // that state would leave stale.
        let attachedIDs = Set(layouts.flatMap { ($0.columns ?? []).map(\.id) })
        let nilDefinition = fieldValues.filter { $0.definition == nil }
        let dangling = fieldValues.filter { value in
            guard let id = value.definition?.id else { return false }
            return !attachedIDs.contains(id)
        }

        return Section {
            LabeledContent("Definition is nil", value: "\(nilDefinition.count)")
                .foregroundStyle(nilDefinition.isEmpty ? Color.primary : .red)
            ForEach(nilDefinition, id: \.persistentModelID) { value in
                orphanRow(value)
            }

            LabeledContent("Definition exists, in no layout", value: "\(dangling.count)")
                .foregroundStyle(dangling.isEmpty ? Color.primary : .orange)
            ForEach(dangling, id: \.persistentModelID) { value in
                orphanRow(value)
            }
        } header: {
            Text("Orphaned TaskFieldValue Rows")
        } footer: {
            Text("§3.5: deleting a column nullifies its cells rather than cascading, so the first count is expected in normal use, cleared by Phase 2's sweep. §10 doesn't verify the second — a definition that still exists but was dropped from every layout's column list without being deleted.")
        }
    }

    private func orphanRow(_ value: TaskFieldValue) -> some View {
        let slots = FieldValueSlots.populated(value)
        return Text("\(value.task?.title ?? "no task") · \(slots.isEmpty ? "no slot populated" : slots.joined(separator: ", "))")
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
    }
}

// MARK: - Per-task column breakdown

private struct TaskColumnBreakdown: View {
    let task: StudyTask
    let board: SubjectTaskBoard?

    var body: some View {
        let columns = TaskSeeding.orderedColumns(of: board?.layout)

        if columns.isEmpty {
            Text(board == nil
                 ? "No SubjectTaskBoard resolves for this task (subject is nil, or the subject has no board yet) — its layout can't be determined."
                 : "This layout has no columns.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(columns, id: \.persistentModelID) { column in
                TaskColumnRow(task: task, column: column)
            }
        }
    }
}

private struct TaskColumnRow: View {
    let task: StudyTask
    let column: TaskFieldDefinition

    var body: some View {
        let content = task.content(for: column)

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(column.name.isEmpty ? "Untitled column" : column.name)
                    .font(.subheadline.bold())
                Text(column.coreKey == nil ? "custom" : "core")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(".\(column.kind.rawValue)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text("content(for:) → \(describeContent(content))")
                .font(.caption)

            storageDetail
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var storageDetail: some View {
        if let coreKey = column.coreKey {
            Text(rawCoreDescription(for: coreKey))
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        } else if let value = task.fieldValues?.first(where: { $0.definition?.id == column.id }) {
            let populated = FieldValueSlots.populated(value)
            let mismatched = FieldValueSlots.isMismatched(value, kind: column.kind)

            Text("TaskFieldValue: \(populated.isEmpty ? "no slot populated" : populated.joined(separator: ", "))")
                .font(.caption2.monospaced())
                .foregroundStyle(mismatched ? .red : .secondary)

            if mismatched {
                Text("MISMATCH — expected \(FieldValueSlots.expectedSlot(for: column.kind)) for kind .\(column.kind.rawValue)")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }
        } else {
            Text("no TaskFieldValue row — column untouched")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func rawCoreDescription(for coreKey: TaskCoreField) -> String {
        switch coreKey {
        case .title:
            return "StudyTask.title = \"\(task.title)\""
        case .dueDate:
            return "StudyTask.dueDate = \(task.dueDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "nil")"
        case .isDone:
            let completed = task.completedAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "nil"
            return "StudyTask.isDone = \(task.isDone), completedAt = \(completed)"
        }
    }

    private func describeContent(_ content: TaskFieldContent) -> String {
        switch content {
        case .empty:
            return "empty"
        case .text(let text):
            return "\"\(text)\""
        case .number(let number):
            return number.formatted()
        case .date(let date):
            return date.formatted(date: .abbreviated, time: .shortened)
        case .flag(let flag):
            return flag ? "true" : "false"
        case .options(let options):
            return options.isEmpty ? "[]" : options.map(\.label).joined(separator: ", ")
        }
    }
}

// MARK: - Layout column summary

private struct LayoutColumnRow: View {
    let column: TaskFieldDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(column.name.isEmpty ? "Untitled" : column.name).font(.subheadline)
                Text(".\(column.kind.rawValue)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                if column.coreKey != nil {
                    Text("core").font(.caption2).foregroundStyle(.secondary)
                }
            }

            if column.kind == .select || column.kind == .multiSelect {
                optionSwatches
            }
        }
    }

    private var optionSwatches: some View {
        let options = (column.options ?? []).sorted { $0.sortIndex < $1.sortIndex }
        return HStack(spacing: 10) {
            ForEach(options, id: \.persistentModelID) { option in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: option.colorHex) ?? .gray)
                        .frame(width: 10, height: 10)
                    Text(option.label).font(.caption2)
                }
            }
        }
    }
}

// MARK: - Shared corruption check

// Shared by the per-task column breakdown and the orphan-value audit above — what counts
// as "corrupted" (a populated slot disagreeing with kind, or more than one slot populated)
// has to be identical in both places or the two sections of this same screen would disagree
// with each other about the same row.
private enum FieldValueSlots {
    static func populated(_ value: TaskFieldValue) -> [String] {
        var names: [String] = []
        if value.textValue != nil { names.append("textValue") }
        if value.numberValue != nil { names.append("numberValue") }
        if value.dateValue != nil { names.append("dateValue") }
        if value.boolValue != nil { names.append("boolValue") }
        if let options = value.selectedOptions, !options.isEmpty { names.append("selectedOptions") }
        return names
    }

    static func expectedSlot(for kind: TaskFieldKind) -> String {
        switch kind {
        case .text: return "textValue"
        case .date: return "dateValue"
        case .checkbox: return "boolValue"
        case .select, .multiSelect: return "selectedOptions"
        case .number, .scale: return "numberValue"
        }
    }

    static func isMismatched(_ value: TaskFieldValue, kind: TaskFieldKind) -> Bool {
        let names = populated(value)
        if names.count > 1 { return true }
        if let only = names.first { return only != expectedSlot(for: kind) }
        return false
    }
}

#Preview {
    NavigationStack {
        DebugTaskDataView()
    }
    // Also needs Subject: the sample-task generator and every subjectName lookup on this
    // screen read it, and @Query fatals at runtime against a container that never
    // registered the model it's querying.
    .modelContainer(for: TaskSchema.models + [Subject.self], inMemory: true)
}
