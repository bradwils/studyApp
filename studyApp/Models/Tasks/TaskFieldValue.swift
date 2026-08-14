//  TaskFieldValue.swift
//  studyApp
//
//  A single cell — one custom-column value belonging to one StudyTask.
//  Sparse storage: exactly one of the typed slots below is populated, chosen by
//  the definition's kind. See StudyTask+Fields.swift for the accessor that reads it.

import Foundation
import SwiftData

@Model
final class TaskFieldValue {
    var id: UUID = UUID()

    // Nullify: if a column is deleted the cell is orphaned rather than silently dropped,
    // so a mis-click in the layout editor doesn't destroy data. Swept up in Phase 2.
    @Relationship(deleteRule: .nullify)
    var definition: TaskFieldDefinition? = nil

    var textValue: String? = nil
    var numberValue: Double? = nil
    var dateValue: Date? = nil
    var boolValue: Bool? = nil

    // Nullify — deleting this cell must not cascade into deleting the shared options it
    // points at; they belong to the column, not the cell.
    @Relationship(deleteRule: .nullify)
    var selectedOptions: [TaskFieldOption]? = nil

    // Inverse of StudyTask.fieldValues — that side declares the inverse, so this stays a
    // plain property (declaring inverse: on both sides is a runtime crash).
    var task: StudyTask? = nil

    init(
        id: UUID = UUID(),
        definition: TaskFieldDefinition? = nil,
        textValue: String? = nil,
        numberValue: Double? = nil,
        dateValue: Date? = nil,
        boolValue: Bool? = nil,
        selectedOptions: [TaskFieldOption]? = nil,
        task: StudyTask? = nil
    ) {
        self.id = id
        self.definition = definition
        self.textValue = textValue
        self.numberValue = numberValue
        self.dateValue = dateValue
        self.boolValue = boolValue
        self.selectedOptions = selectedOptions
        self.task = task
    }
}
