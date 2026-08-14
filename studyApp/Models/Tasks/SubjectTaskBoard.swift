//  SubjectTaskBoard.swift
//  studyApp
//
//  Binds a subject to the layout its board uses. Exists only so Subject.swift
//  doesn't need a `layout` property while other REVIEW_* branches touch that file —
//  see docs/StudyTasks.md §3.7.

import Foundation
import SwiftData

@Model
final class SubjectTaskBoard {
    var id: UUID = UUID()

    // One-way, no inverse on Subject — deliberate isolation (docs/StudyTasks.md §7).
    // Nullify — deleting this binding must not cascade into deleting the subject it points at.
    @Relationship(deleteRule: .nullify)
    var subject: Subject? = nil

    // One-way, no inverse on TaskBoardLayout — a layout doesn't need to know which boards use it.
    // Nullify — deleting this binding must not cascade into deleting the shared layout it points at.
    @Relationship(deleteRule: .nullify)
    var layout: TaskBoardLayout? = nil

    var createdAt: Date = Date.now

    init(id: UUID = UUID(), subject: Subject? = nil, layout: TaskBoardLayout? = nil, createdAt: Date = Date.now) {
        self.id = id
        self.subject = subject
        self.layout = layout
        self.createdAt = createdAt
    }
}
