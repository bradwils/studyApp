//  TaskSchema.swift
//  studyApp
//
//  Central registration list so App/StudyAppApp.swift only needs one line
//  appended to its .modelContainer(for:) call — see docs/StudyTasks.md §7.

import SwiftData

enum TaskSchema {
    static let models: [any PersistentModel.Type] = [
        StudyTask.self,
        TaskFieldValue.self,
        TaskFieldDefinition.self,
        TaskFieldOption.self,
        TaskBoardLayout.self,
        SubjectTaskBoard.self
    ]
}
