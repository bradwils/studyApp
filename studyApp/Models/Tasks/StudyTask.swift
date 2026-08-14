//  StudyTask.swift
//  studyApp
//
//  A single work item on a subject's task board.
//  Named StudyTask, never Task — Task is Swift concurrency's type, and shadowing it
//  in this target causes baffling errors.

import Foundation
import SwiftData

@Model
final class StudyTask {
    var id: UUID = UUID()

    // Every StudyTask must be identifiable by a unique id, mirroring StudySession.
    #Unique<StudyTask>([\.id])

    // --- Core fields: typed because the whole app needs to sort, filter and reason about them ---
    var title: String = ""
    var isDone: Bool = false
    var completedAt: Date? = nil   // set alongside isDone; gives "time from created to done" for free
    var dueDate: Date? = nil
    var createdAt: Date = Date.now
    var sortIndex: Int = 0         // manual ordering within a board; drag-to-reorder writes here

    // Mirrors the StudySession pattern: keep the name so history survives subject deletion
    @Relationship(deleteRule: .nullify)
    var subject: Subject? = nil
    var subjectName: String? = nil

    // Custom column values. Cascade — a cell has no meaning without its task. Declares the
    // inverse (TaskFieldValue.task) since exactly one side of the pair must.
    @Relationship(deleteRule: .cascade, inverse: \TaskFieldValue.task)
    var fieldValues: [TaskFieldValue]? = nil

    init(
        id: UUID = UUID(),
        title: String = "",
        isDone: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        createdAt: Date = Date.now,
        sortIndex: Int = 0,
        subject: Subject? = nil,
        subjectName: String? = nil,
        fieldValues: [TaskFieldValue]? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.subject = subject
        self.subjectName = subjectName
        self.fieldValues = fieldValues
    }
}
