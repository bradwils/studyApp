//  TaskFieldDefinition.swift
//  studyApp
//
//  A single column in a task board layout — either bound to a core StudyTask
//  property (coreKey set) or backed by TaskFieldValue rows (coreKey nil).

import Foundation
import SwiftData

@Model
final class TaskFieldDefinition {
    var id: UUID = UUID()
    var name: String = ""              // the header: "Pages", "Work type", "Effort"
    var kindRaw: String = TaskFieldKind.text.rawValue   // TaskFieldKind
    var coreKeyRaw: String? = nil      // TaskCoreField — nil means this is a custom field
    var sortIndex: Int = 0
    var showInRow: Bool = true         // surface in the collapsed list row, vs detail-only
    var isRequired: Bool = false

    // Kind-specific config. Only the slots relevant to `kind` are read; the rest stay at
    // their defaults. Cheaper and far simpler to reason about than a polymorphic config blob.
    var unitLabel: String? = nil
    var scaleMin: Double = 0
    var scaleMax: Double = 5
    var scaleStep: Double = 1

    // Cascade — an option has no meaning without the column that defines it.
    @Relationship(deleteRule: .cascade)
    var options: [TaskFieldOption]? = nil

    // Inverse of TaskBoardLayout.columns — that side declares the inverse, so this stays a
    // plain property (declaring inverse: on both sides is a runtime crash).
    var layout: TaskBoardLayout? = nil

    var kind: TaskFieldKind {
        get { TaskFieldKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var coreKey: TaskCoreField? {
        get { coreKeyRaw.flatMap { TaskCoreField(rawValue: $0) } }
        set { coreKeyRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        kind: TaskFieldKind = .text,
        coreKey: TaskCoreField? = nil,
        sortIndex: Int = 0,
        showInRow: Bool = true,
        isRequired: Bool = false,
        unitLabel: String? = nil,
        scaleMin: Double = 0,
        scaleMax: Double = 5,
        scaleStep: Double = 1,
        options: [TaskFieldOption]? = nil,
        layout: TaskBoardLayout? = nil
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.coreKeyRaw = coreKey?.rawValue
        self.sortIndex = sortIndex
        self.showInRow = showInRow
        self.isRequired = isRequired
        self.unitLabel = unitLabel
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
        self.scaleStep = scaleStep
        self.options = options
        self.layout = layout
    }
}
