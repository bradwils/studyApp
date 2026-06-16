//  Subject.swift
//  studyApp
//
//  Model representing a study subject.

import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var code: String
    var createdAt: Date

    // Nullify so deleting a subject preserves session history (sessions fall back to subjectName)
    @Relationship(deleteRule: .nullify, inverse: \StudySession.subject)
    var sessions: [StudySession]

    init(id: UUID = UUID(), name: String, code: String, createdAt: Date = Date(), sessions: [StudySession] = []) {
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = createdAt
        self.sessions = sessions
    }
}
