//
//  studyAppTests.swift
//  studyAppTests
//
//  Created by brad wils on 27/10/25.
//

import Testing
import SwiftData
@testable import studyApp

// The original tests here covered UserProfileStore, which was deleted when the
// SwiftData migration completed — they could no longer compile.
struct studyAppTests {

    @Test("Subject inserts and fetches through an in-memory container")
    func subjectPersistsInMemory() throws {
        let container = try ModelContainer(
            for: Subject.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        context.insert(Subject(name: "Physics", code: "PHYS101"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Subject>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Physics")
    }
}
