//  TaskBoardVM.swift
//  studyApp
//
//  Board-level state: which subject is selected, how its tasks are sorted and
//  filtered, and the create/delete/toggle actions a board exposes.

import Foundation
import SwiftData

@Observable
final class TaskBoardVM {
    var selectedSubject: Subject?

    // Custom-column sorting needs task.content(for:), which needs a specific
    // TaskFieldDefinition — not knowable here as a fixed case. Phase 1 covers the three
    // core fields (docs/StudyTasks.md §10); adding a `.custom(TaskFieldDefinition)` case
    // later only means one more branch in isOrderedBefore, nothing else changes.
    enum SortOption: String, CaseIterable, Identifiable {
        case title
        case dueDate
        case doneStatus

        var id: String { rawValue }

        var label: String {
            switch self {
            case .title: return "Title"
            case .dueDate: return "Due Date"
            case .doneStatus: return "Status"
            }
        }
    }

    var sortOption: SortOption = .dueDate
    var hideCompleted: Bool = false

    // A pure transform over the view's own @Query results (docs/StudyTasks.md §6) —
    // sorting by a custom column can't be expressed as a SortDescriptor, so both the
    // subject filter and the sort happen here in memory rather than at the query.
    func visibleTasks(from tasks: [StudyTask]) -> [StudyTask] {
        guard let selectedSubject else { return [] }

        var filtered = tasks.filter { $0.subject?.id == selectedSubject.id }
        if hideCompleted {
            filtered.removeAll { $0.isDone }
        }
        return filtered.sorted(by: isOrderedBefore)
    }

    private func isOrderedBefore(_ lhs: StudyTask, _ rhs: StudyTask) -> Bool {
        switch sortOption {
        case .title:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        case .dueDate:
            switch (lhs.dueDate, rhs.dueDate) {
            case let (left?, right?): return left < right
            case (nil, nil): return lhs.sortIndex < rhs.sortIndex
            case (nil, _): return false    // no due date sorts after any date
            case (_, nil): return true
            }
        case .doneStatus:
            if lhs.isDone != rhs.isDone { return rhs.isDone }   // not-done before done
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    func addTask(context: ModelContext) {
        guard let selectedSubject else { return }

        // Matching on an optional relationship's id is exactly the predicate shape
        // SwiftData handles badly (see TaskSeeding.board(for:in:)) — filter in memory.
        let siblingTasks = ((try? context.fetch(FetchDescriptor<StudyTask>())) ?? [])
            .filter { $0.subject?.id == selectedSubject.id }
        let nextSortIndex = (siblingTasks.map(\.sortIndex).max() ?? -1) + 1

        let task = StudyTask(
            title: "New Task",
            sortIndex: nextSortIndex,
            subject: selectedSubject,
            subjectName: selectedSubject.name
        )
        context.insert(task)
        try? context.save()
    }

    func deleteTasks(_ tasks: [StudyTask], context: ModelContext) {
        for task in tasks {
            context.delete(task)
        }
        try? context.save()
    }

    // Routed through the seam so the isDone <-> completedAt invariant stays intact —
    // flipping task.isDone directly here would be the exact bug the seam exists to
    // prevent (docs/StudyTasks.md §4). No-op if the layout has no Done column at all.
    func toggleDone(_ task: StudyTask, columns: [TaskFieldDefinition], context: ModelContext) {
        guard let doneColumn = columns.first(where: { $0.coreKey == .isDone }) else { return }
        task.setContent(.flag(!task.isDone), for: doneColumn, context: context)
        try? context.save()
    }
}
