//  TaskFieldKind.swift
//  studyApp
//
//  The fixed catalog of task column types, the three exposable core fields,
//  and the in-memory transfer shape used by the StudyTask accessor seam.

import Foundation

// Not persisted as a model — a String-backed enum stored on TaskFieldDefinition.kindRaw.
// Each case names the TaskFieldValue slot it reads/writes so the slot<->kind mapping is
// readable without cross-referencing docs/StudyTasks.md §3.2.
enum TaskFieldKind: String, CaseIterable {
    case text          // TaskFieldValue.textValue
    case date          // TaskFieldValue.dateValue
    case checkbox      // TaskFieldValue.boolValue
    case select        // TaskFieldValue.selectedOptions (exactly one)
    case multiSelect   // TaskFieldValue.selectedOptions (many)
    case number        // TaskFieldValue.numberValue
    case scale         // TaskFieldValue.numberValue
}

// The only StudyTask properties a column is allowed to point at. Stored on
// TaskFieldDefinition.coreKeyRaw; nil there means the column is a custom field instead.
enum TaskCoreField: String, Codable, CaseIterable {
    case title
    case dueDate
    case isDone
}

// Not persisted — the in-memory shape of "whatever is in this cell", returned by
// StudyTask.content(for:) regardless of whether the column is core or custom.
enum TaskFieldContent: Equatable {
    case empty
    case text(String)
    case number(Double)
    case date(Date)
    case flag(Bool)
    case options([TaskFieldOption])
}
