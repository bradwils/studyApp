//  TaskBoardLayout.swift
//  studyApp
//
//  A named, shared column template. Several subjects can point at the same
//  layout; editing it updates every subject that does. Diverging is an
//  explicit act — duplicate the layout, then repoint one subject at the copy.

import Foundation
import SwiftData

@Model
final class TaskBoardLayout {
    var id: UUID = UUID()
    var name: String = ""          // "Default", "Coding subject", "Reading-heavy"
    var isDefault: Bool = false    // seeded template, offered to new subjects

    // Cascade — a column has no meaning without the layout that owns it. Declares the
    // inverse (TaskFieldDefinition.layout) since exactly one side of the pair must.
    @Relationship(deleteRule: .cascade, inverse: \TaskFieldDefinition.layout)
    var columns: [TaskFieldDefinition]? = nil

    init(id: UUID = UUID(), name: String = "", isDefault: Bool = false, columns: [TaskFieldDefinition]? = nil) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.columns = columns
    }

    // The seeded template every new subject is offered. Column set is fixed by
    // docs/StudyTasks.md §8 Phase 0 — do not add/remove/reorder without updating that doc.
    static func makeDefault() -> TaskBoardLayout {
        let layout = TaskBoardLayout(name: "Default", isDefault: true)

        // No "Done" option here on purpose. Completion is the isDone core field, reached
        // through the Done checkbox column below — a select option would be a second,
        // silent source of truth that the session link and every stat would ignore.
        let statusOptions = [
            TaskFieldOption(label: "Not started", colorHex: "#8E8E93", sortIndex: 0),
            TaskFieldOption(label: "In progress", colorHex: "#007AFF", sortIndex: 1),
            TaskFieldOption(label: "Blocked", colorHex: "#FF3B30", sortIndex: 2)
        ]

        let workTypeOptions = [
            TaskFieldOption(label: "Physical", colorHex: "#FF9500", sortIndex: 0),
            TaskFieldOption(label: "Canvas", colorHex: "#AF52DE", sortIndex: 1),
            TaskFieldOption(label: "Code", colorHex: "#5AC8FA", sortIndex: 2),
            TaskFieldOption(label: "Worksheet", colorHex: "#FFCC00", sortIndex: 3),
            TaskFieldOption(label: "Reading", colorHex: "#A2845E", sortIndex: 4)
        ]

        let columns = [
            TaskFieldDefinition(name: "Title", kind: .text, coreKey: .title, sortIndex: 0, showInRow: true, isRequired: true),
            TaskFieldDefinition(name: "Done", kind: .checkbox, coreKey: .isDone, sortIndex: 1, showInRow: true),
            TaskFieldDefinition(name: "Due date", kind: .date, coreKey: .dueDate, sortIndex: 2, showInRow: true),
            TaskFieldDefinition(name: "Status", kind: .select, sortIndex: 3, showInRow: true, options: statusOptions),
            TaskFieldDefinition(name: "Work type", kind: .select, sortIndex: 4, showInRow: false, options: workTypeOptions),
            TaskFieldDefinition(name: "Work on", kind: .date, sortIndex: 5, showInRow: false),
            TaskFieldDefinition(name: "Effort", kind: .scale, sortIndex: 6, showInRow: false, scaleMin: 1, scaleMax: 5, scaleStep: 1),
            TaskFieldDefinition(name: "Notes", kind: .text, sortIndex: 7, showInRow: false)
        ]

        for column in columns {
            column.layout = layout
        }
        layout.columns = columns

        return layout
    }
}
