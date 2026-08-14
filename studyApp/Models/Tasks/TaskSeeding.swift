//  TaskSeeding.swift
//  studyApp
//
//  Idempotent first-run setup for the task board: makes sure a default layout
//  exists, and that a subject has a binding pointing at one.

import Foundation
import SwiftData

enum TaskSeeding {

    // Fetches directly rather than taking an injected @Query result, because both callers
    // (the board view's .task and the debug tools) need this to be safe to call at any
    // moment, not just from a view that happens to already query layouts.
    @discardableResult
    static func ensureDefaultLayout(in context: ModelContext) -> TaskBoardLayout? {
        var descriptor = FetchDescriptor<TaskBoardLayout>(
            predicate: #Predicate { $0.isDefault }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor), let layout = existing.first {
            return layout
        }

        let layout = TaskBoardLayout.makeDefault()
        context.insert(layout)
        try? context.save()
        return layout
    }

    // Returns the subject's board, creating one against the default layout on first use.
    @discardableResult
    static func board(for subject: Subject, in context: ModelContext) -> SubjectTaskBoard? {
        // Filtered in memory rather than via #Predicate: matching on an optional relationship's
        // id is exactly the shape SwiftData predicates handle badly, and there is one board per
        // subject — tens of rows, not thousands.
        let boards = (try? context.fetch(FetchDescriptor<SubjectTaskBoard>())) ?? []
        if let existing = boards.first(where: { $0.subject?.id == subject.id }) {
            return existing
        }

        guard let layout = ensureDefaultLayout(in: context) else { return nil }

        let board = SubjectTaskBoard(subject: subject, layout: layout)
        context.insert(board)
        try? context.save()
        return board
    }

    // Columns are stored unordered; every caller wants them in sortIndex order.
    static func orderedColumns(of layout: TaskBoardLayout?) -> [TaskFieldDefinition] {
        (layout?.columns ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }
}
