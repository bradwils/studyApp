//  TaskEditorVM.swift
//  studyApp
//
//  Single-task form state for TaskDetailView. Column editing itself goes through
//  TaskFieldEditor, which writes through the seam directly — this VM only holds the
//  UI-adjacent state a single-task screen still needs on top of that: delete
//  confirmation, and the one validation rule Phase 1 has (a task needs a title).

import Foundation
import SwiftData

@Observable
final class TaskEditorVM {
    var isShowingDeleteConfirmation = false

    func isTitleValid(_ task: StudyTask) -> Bool {
        !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func deleteTask(_ task: StudyTask, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }
}
