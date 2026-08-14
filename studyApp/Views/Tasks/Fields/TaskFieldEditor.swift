//  TaskFieldEditor.swift
//  studyApp
//
//  Editable rendering of one cell — the write half of the switch pair described in
//  docs/StudyTasks.md §4/§5. Mirrors the resolved content into local @State so typing
//  and dragging feel instant, then pushes every change straight back through the
//  accessor seam — there is no save/cancel step anywhere in this app.

import SwiftUI
import SwiftData

struct TaskFieldEditor: View {
    let column: TaskFieldDefinition
    let task: StudyTask

    @Environment(\.modelContext) private var modelContext
    @State private var content: TaskFieldContent
    // A separate buffer for .number: binding a TextField straight to a re-formatted
    // Double fights the user mid-keystroke (typing "3" reformats to "3.0" and so on).
    @State private var numberText: String

    init(column: TaskFieldDefinition, task: StudyTask) {
        self.column = column
        self.task = task
        let initialContent = task.content(for: column)
        _content = State(initialValue: initialContent)
        if case .number(let value) = initialContent {
            _numberText = State(initialValue: Self.formatNumber(value))
        } else {
            _numberText = State(initialValue: "")
        }
    }

    var body: some View {
        Group {
            switch column.kind {
            case .text: textEditor
            case .date: dateEditor
            case .checkbox: checkboxEditor
            case .select: selectEditor
            case .multiSelect: multiSelectEditor
            case .number: numberEditor
            case .scale: scaleEditor
            }
        }
        .onChange(of: content) { oldValue, newValue in
            // onChange already only fires on a real change, but a value round-tripping
            // back to what it started as (e.g. type-then-undo) is still worth skipping.
            guard newValue != oldValue else { return }
            task.setContent(newValue, for: column, context: modelContext)
            try? modelContext.save()
        }
    }

    // MARK: - .text

    private var textEditor: some View {
        TextField(column.name, text: textBinding, axis: .vertical)
            .lineLimit(1...5)
    }

    private var textBinding: Binding<String> {
        Binding(
            get: {
                if case .text(let value) = content { return value }
                return ""
            },
            // Always written as .text, even when empty. The core Title accessor
            // (setCoreContent) only accepts .text, never .empty — collapsing "" to
            // .empty here would silently fail to clear a title.
            set: { content = .text($0) }
        )
    }

    // MARK: - .date

    @ViewBuilder
    private var dateEditor: some View {
        if case .date(let date) = content {
            HStack {
                DatePicker(column.name, selection: dateBinding(current: date), displayedComponents: .date)
                    .datePickerStyle(.compact)
                Button {
                    content = .empty
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear \(column.name)")
            }
        } else {
            // A DatePicker can't represent nil, so an unset date is a button rather than
            // a picker silently defaulted to today — nothing is written until this is tapped.
            Button {
                content = .date(.now)
            } label: {
                Label("Set \(column.name)", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(.plain)
        }
    }

    private func dateBinding(current date: Date) -> Binding<Date> {
        Binding(get: { date }, set: { content = .date($0) })
    }

    // MARK: - .checkbox

    private var checkboxEditor: some View {
        Toggle(column.name, isOn: flagBinding)
    }

    private var flagBinding: Binding<Bool> {
        Binding(
            get: {
                if case .flag(let value) = content { return value }
                return false
            },
            set: { content = .flag($0) }
        )
    }

    // MARK: - .select

    private var selectEditor: some View {
        Menu {
            Button("Clear", role: .destructive) { content = .empty }
            Divider()
            ForEach(sortedOptions, id: \.persistentModelID) { option in
                Button {
                    content = .options([option])
                } label: {
                    HStack {
                        TaskOptionPill(option: option)
                        Spacer()
                        if isChosenInSelect(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            selectSummary
        }
    }

    private var selectSummary: some View {
        HStack {
            if let selectedOption {
                TaskOptionPill(option: selectedOption)
            } else {
                Text("Select \(column.name)")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private var selectedOption: TaskFieldOption? {
        if case .options(let opts) = content { return opts.first }
        return nil
    }

    private func isChosenInSelect(_ option: TaskFieldOption) -> Bool {
        selectedOption?.id == option.id
    }

    // MARK: - .multiSelect

    private var multiSelectEditor: some View {
        TaskFieldFlowLayout(spacing: 6) {
            ForEach(sortedOptions, id: \.persistentModelID) { option in
                Button {
                    toggleMultiSelect(option)
                } label: {
                    TaskOptionPill(option: option, isSelected: isChosenInMultiSelect(option))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var multiSelectedOptions: [TaskFieldOption] {
        if case .options(let opts) = content { return opts }
        return []
    }

    private func isChosenInMultiSelect(_ option: TaskFieldOption) -> Bool {
        multiSelectedOptions.contains { $0.id == option.id }
    }

    private func toggleMultiSelect(_ option: TaskFieldOption) {
        var updated = multiSelectedOptions
        if let index = updated.firstIndex(where: { $0.id == option.id }) {
            updated.remove(at: index)
        } else {
            updated.append(option)
        }
        content = updated.isEmpty ? .empty : .options(updated)
    }

    // MARK: - .select / .multiSelect shared

    // Storage is unordered (docs/StudyTasks.md §3.4) — every display site re-sorts.
    private var sortedOptions: [TaskFieldOption] {
        (column.options ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    // MARK: - .number

    private var numberEditor: some View {
        HStack {
            TextField(column.name, text: $numberText)
                .keyboardType(.decimalPad)
                .onChange(of: numberText) { _, newValue in
                    syncNumber(from: newValue)
                }
            if let unitLabel = column.unitLabel, !unitLabel.isEmpty {
                Text(unitLabel)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func syncNumber(from text: String) {
        if text.isEmpty {
            content = .empty
        } else if let parsed = Double(text) {
            content = .number(parsed)
        }
        // A bare "-" or a trailing "." mid-edit parses to nil and is left un-synced;
        // the next valid keystroke catches up, so storage never receives garbage.
    }

    // MARK: - .scale

    private var scaleEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(column.name)
                Spacer()
                Text(Self.formatNumber(scaleValue))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(Self.formatNumber(scaleRange.lowerBound))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Slider(value: scaleBinding, in: scaleRange, step: max(column.scaleStep, 0.01))
                Text(Self.formatNumber(scaleRange.upperBound))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var scaleValue: Double {
        if case .number(let value) = content { return value }
        return scaleRange.lowerBound
    }

    private var scaleBinding: Binding<Double> {
        Binding(get: { scaleValue }, set: { content = .number($0) })
    }

    // Guards against a misconfigured column (scaleMin > scaleMax) crashing the Slider,
    // which requires a valid, non-inverted ClosedRange.
    private var scaleRange: ClosedRange<Double> {
        min(column.scaleMin, column.scaleMax)...max(column.scaleMin, column.scaleMax)
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.2f", value)
    }
}

#Preview {
    TaskFieldEditorPreview()
        .modelContainer(for: TaskSchema.models, inMemory: true)
}

// One task against the seeded default layout, which covers all seven kinds.
private struct TaskFieldEditorPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var task: StudyTask?
    @State private var columns: [TaskFieldDefinition] = []

    var body: some View {
        Group {
            if let task {
                List(columns, id: \.persistentModelID) { column in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(column.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TaskFieldEditor(column: column, task: task)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                ProgressView()
            }
        }
        .task { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        guard task == nil else { return }

        let layout = TaskBoardLayout.makeDefault()
        let newTask = StudyTask(title: "Create data dictionary for tutorial 3")
        modelContext.insert(layout)
        modelContext.insert(newTask)

        columns = TaskSeeding.orderedColumns(of: layout)
        task = newTask
    }
}
