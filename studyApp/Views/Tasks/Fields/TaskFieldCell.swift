//  TaskFieldCell.swift
//  studyApp
//
//  Read-only rendering of one cell. Takes resolved content rather than a task so it
//  stays dumb and previewable — TaskRowView / TaskDetailView own calling content(for:).

import SwiftUI
import SwiftData

struct TaskFieldCell: View {
    let column: TaskFieldDefinition
    let content: TaskFieldContent

    var body: some View {
        switch column.kind {
        case .text: textCell
        case .date: dateCell
        case .checkbox: checkboxCell
        case .select, .multiSelect: optionsCell
        case .number: numberCell
        case .scale: scaleCell
        }
    }

    @ViewBuilder
    private var textCell: some View {
        if case .text(let value) = content, !value.isEmpty {
            Text(value)
                .lineLimit(2)
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var dateCell: some View {
        if case .date(let value) = content {
            Text(value, style: .date)
        } else {
            placeholder
        }
    }

    private var checkboxCell: some View {
        // Empty (a never-touched custom checkbox) reads as unchecked — there is no
        // third visual state, matching a boolean's own nature.
        let isChecked: Bool
        if case .flag(let value) = content {
            isChecked = value
        } else {
            isChecked = false
        }
        return Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
    }

    @ViewBuilder
    private var optionsCell: some View {
        if case .options(let options) = content, !options.isEmpty {
            TaskFieldFlowLayout(spacing: 6) {
                ForEach(sortedOptions(options), id: \.persistentModelID) { option in
                    TaskOptionPill(option: option)
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var numberCell: some View {
        if case .number(let value) = content {
            Text(unitSuffixed(formatNumber(value)))
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var scaleCell: some View {
        if case .number(let value) = content {
            Text("\(formatNumber(value)) / \(formatNumber(column.scaleMax))")
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Text("—")
            .foregroundStyle(.tertiary)
    }

    // Storage is unordered (docs/StudyTasks.md §3.4) — every display site re-sorts.
    private func sortedOptions(_ options: [TaskFieldOption]) -> [TaskFieldOption] {
        options.sorted { $0.sortIndex < $1.sortIndex }
    }

    private func unitSuffixed(_ text: String) -> String {
        guard let unitLabel = column.unitLabel, !unitLabel.isEmpty else { return text }
        return "\(text) \(unitLabel)"
    }

    private func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.2f", value)
    }
}

// A leading-aligned wrap layout: chips fill left to right and break onto a new line
// once the next one would overflow. Shared by TaskFieldCell (read-only chips) and
// TaskFieldEditor (tappable multiSelect chips) — internal, not private, for that reason.
struct TaskFieldFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > 0, origin.x + size.width > maxWidth {
                contentWidth = max(contentWidth, origin.x - spacing)
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        contentWidth = max(contentWidth, origin.x - spacing)

        let height = origin.y + rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : max(contentWidth, 0), height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > bounds.minX, origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    TaskFieldCellPreview()
        .modelContainer(for: TaskSchema.models, inMemory: true)
}

// Exercises all seven kinds side by side, which the seeded default layout covers.
private struct TaskFieldCellPreview: View {
    private let columns: [TaskFieldDefinition]

    init() {
        columns = TaskSeeding.orderedColumns(of: TaskBoardLayout.makeDefault())
    }

    private func sampleContent(for column: TaskFieldDefinition) -> TaskFieldContent {
        switch column.name {
        case "Title": return .text("Create data dictionary for tutorial 3")
        case "Done": return .flag(true)
        case "Due date": return .date(.now)
        case "Status": return (column.options?.first).map { .options([$0]) } ?? .empty
        case "Work type": return .empty
        case "Work on": return .empty
        case "Effort": return .number(3)
        case "Notes": return .empty
        case "Tags": return .options(column.options ?? [])
        case "Pages": return .number(12)
        default: return .empty
        }
    }

    var body: some View {
        List(columns, id: \.persistentModelID) { column in
            HStack(alignment: .top) {
                Text(column.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
                TaskFieldCell(column: column, content: sampleContent(for: column))
                Spacer(minLength: 0)
            }
        }
    }
}
