//
//  TaskBoardTests.swift
//  studyAppTests
//
//  Covers the pieces docs/StudyTasks.md itself flags as unverified: whether the
//  .nullify/.cascade relationships actually fire, and whether the content(for:)/
//  setContent(...) accessor seam round-trips every field kind correctly.

import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
struct TaskBoardTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(
            [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self, RemoteUser.self]
                + TaskSchema.models
        )
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Seeding creates the 10-column default layout and is idempotent")
    func seedingIsIdempotent() throws {
        let context = try makeContext()

        let layout = TaskSeeding.ensureDefaultLayout(in: context)
        #expect(layout?.columns?.count == 10)

        let again = TaskSeeding.ensureDefaultLayout(in: context)
        #expect(again?.id == layout?.id)

        let allLayouts = try context.fetch(FetchDescriptor<TaskBoardLayout>())
        #expect(allLayouts.count == 1)
    }

    @Test("Subject.board(for:) reuses one binding per subject")
    func boardBindingIsReused() throws {
        let context = try makeContext()
        let subject = Subject(name: "Physics", code: "PHYS")
        context.insert(subject)

        let board = TaskSeeding.board(for: subject, in: context)
        let boardAgain = TaskSeeding.board(for: subject, in: context)

        #expect(board?.id == boardAgain?.id)
        #expect(try context.fetch(FetchDescriptor<SubjectTaskBoard>()).count == 1)
    }

    @Test("content/setContent round-trips core fields")
    func coreFieldRoundTrip() throws {
        let context = try makeContext()
        let layout = TaskSeeding.ensureDefaultLayout(in: context)!
        let columns = TaskSeeding.orderedColumns(of: layout)
        let titleColumn = columns.first { $0.coreKey == .title }!
        let dueDateColumn = columns.first { $0.coreKey == .dueDate }!
        let doneColumn = columns.first { $0.coreKey == .isDone }!

        let task = StudyTask()
        context.insert(task)

        task.setContent(.text("Finish problem set"), for: titleColumn, context: context)
        #expect(task.title == "Finish problem set")
        #expect(task.content(for: titleColumn) == .text("Finish problem set"))

        let due = Date.now
        task.setContent(.date(due), for: dueDateColumn, context: context)
        #expect(task.dueDate == due)

        #expect(task.content(for: doneColumn) == .flag(false))
        task.setContent(.flag(true), for: doneColumn, context: context)
        #expect(task.isDone == true)
        #expect(task.completedAt != nil)

        // Re-affirming an already-done task must not move completedAt.
        let firstCompletedAt = task.completedAt
        task.setContent(.flag(true), for: doneColumn, context: context)
        #expect(task.completedAt == firstCompletedAt)

        task.setContent(.flag(false), for: doneColumn, context: context)
        #expect(task.isDone == false)
        #expect(task.completedAt == nil)
    }

    @Test("content/setContent round-trips custom columns without allocating rows for untouched ones")
    func customFieldRoundTrip() throws {
        let context = try makeContext()
        let layout = TaskSeeding.ensureDefaultLayout(in: context)!
        let columns = TaskSeeding.orderedColumns(of: layout)
        let statusColumn = columns.first { $0.name == "Status" }!
        let pagesColumn = columns.first { $0.name == "Pages" }!
        let tagsColumn = columns.first { $0.name == "Tags" }!

        let task = StudyTask()
        context.insert(task)

        #expect(task.content(for: statusColumn) == .empty)
        #expect(task.fieldValues?.isEmpty ?? true)

        let inProgress = statusColumn.options!.first { $0.label == "In progress" }!
        task.setContent(.options([inProgress]), for: statusColumn, context: context)
        #expect(task.content(for: statusColumn) == .options([inProgress]))

        task.setContent(.number(42), for: pagesColumn, context: context)
        #expect(task.content(for: pagesColumn) == .number(42))

        // Untouched multi-select column: no TaskFieldValue should have been allocated for it.
        #expect(task.content(for: tagsColumn) == .empty)
        #expect(task.fieldValues?.count == 2)

        // Writing a mismatched kind (.text to a .select column) is a silent no-op.
        task.setContent(.text("nope"), for: statusColumn, context: context)
        #expect(task.content(for: statusColumn) == .options([inProgress]))

        // Clearing removes the value from the slot but the row can remain (nullify sweep is Phase 2).
        task.setContent(.empty, for: pagesColumn, context: context)
        #expect(task.content(for: pagesColumn) == .empty)
    }

    @Test("Deleting a subject nullifies StudyTask.subject instead of deleting the task")
    func deletingSubjectNullifiesTask() throws {
        let context = try makeContext()
        let subject = Subject(name: "Chemistry", code: "CHEM")
        context.insert(subject)

        let task = StudyTask(title: "Lab report", subject: subject, subjectName: subject.name)
        context.insert(task)
        try context.save()

        context.delete(subject)
        try context.save()

        let remainingTasks = try context.fetch(FetchDescriptor<StudyTask>())
        #expect(remainingTasks.count == 1)
        #expect(remainingTasks.first?.subject == nil)
        #expect(remainingTasks.first?.subjectName == "Chemistry")
    }

    @Test("Deleting a StudyTask cascades to its field values")
    func deletingTaskCascadesFieldValues() throws {
        let context = try makeContext()
        let layout = TaskSeeding.ensureDefaultLayout(in: context)!
        let pagesColumn = TaskSeeding.orderedColumns(of: layout).first { $0.name == "Pages" }!

        let task = StudyTask()
        context.insert(task)
        task.setContent(.number(10), for: pagesColumn, context: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TaskFieldValue>()).count == 1)

        context.delete(task)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TaskFieldValue>()).count == 0)
    }

    @Test("Deleting a column nullifies (orphans) its field values instead of deleting them")
    func deletingColumnOrphansFieldValues() throws {
        let context = try makeContext()
        let layout = TaskSeeding.ensureDefaultLayout(in: context)!
        let pagesColumn = TaskSeeding.orderedColumns(of: layout).first { $0.name == "Pages" }!

        let task = StudyTask()
        context.insert(task)
        task.setContent(.number(10), for: pagesColumn, context: context)
        try context.save()

        context.delete(pagesColumn)
        try context.save()

        let values = try context.fetch(FetchDescriptor<TaskFieldValue>())
        #expect(values.count == 1)
        #expect(values.first?.definition == nil)
        #expect(values.first?.numberValue == 10)
    }

    @Test("Deleting a layout cascades to its columns and their options")
    func deletingLayoutCascadesColumnsAndOptions() throws {
        let context = try makeContext()
        let layout = TaskSeeding.ensureDefaultLayout(in: context)!
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TaskFieldDefinition>()).count == 10)
        #expect(try context.fetch(FetchDescriptor<TaskFieldOption>()).count > 0)

        context.delete(layout)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TaskFieldDefinition>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<TaskFieldOption>()).count == 0)
    }
}
