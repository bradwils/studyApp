//  Subject.swift
//  studyApp
//
//  Model representing a study subject.

import Foundation

struct Subject: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var code: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, code: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = createdAt
    }
}
