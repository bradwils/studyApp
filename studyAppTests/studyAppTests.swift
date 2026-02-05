//
//  studyAppTests.swift
//  studyAppTests
//
//  Created by brad wils on 27/10/25.
//

import Testing
@testable import studyApp

import Foundation

struct studyAppTests {

    // Helper to create a temporary directory for isolated disk tests
    private func makeTempDirectory() throws -> URL {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    @Test("Adding a subject persists to disk")
    func testAddSubjectPersistsToDisk() async throws {
        let dir = try makeTempDirectory()
        let store = await UserProfileStore(
            filename: "profile.json",
            legacySubjectsFilename: "legacy.json",
            directory: dir,
            seedSampleData: false
        )

        await #expect(store.profile.subjects.isEmpty)

        let subject = await Subject(name: "Physics", code: "PHYS101")
        await store.addSubject(subject)

        let reloaded = await UserProfileStore(
            filename: "profile.json",
            legacySubjectsFilename: "legacy.json",
            directory: dir,
            seedSampleData: false
        )

        await #expect(reloaded.profile.subjects.count == 1)
        await #expect(reloaded.profile.subjects.first?.name == "Physics")
    }

    @Test("Removing a subject persists to disk")
    func testRemoveSubjectPersistsToDisk() async throws {
        let dir = try makeTempDirectory()
        let store = await UserProfileStore(
            filename: "profile.json",
            legacySubjectsFilename: "legacy.json",
            directory: dir,
            seedSampleData: false
        )

        let math = await Subject(name: "Math", code: "MATH")
        let chem = Subject(name: "Chem", code: "CHEM")
        await store.addSubject(math)
        store.addSubject(chem)

        await store.removeSubject(id: math.id)

        let reloaded = await UserProfileStore(
            filename: "profile.json",
            legacySubjectsFilename: "legacy.json",
            directory: dir,
            seedSampleData: false
        )

        await #expect(reloaded.profile.subjects.count == 1)
        await #expect(reloaded.profile.subjects.first?.code == "CHEM")
    }

    @Test("Legacy migration imports subjects")
    func testLegacyMigrationImportsSubjects() async throws {
        let dir = try makeTempDirectory()
        let legacySubjects = await [
            Subject(name: "History", code: "HIST"),
            Subject(name: "Biology", code: "BIO")
        ]

        let legacyURL = dir.appendingPathComponent("legacy.json")
        let data = try JSONEncoder().encode(legacySubjects)
        try data.write(to: legacyURL, options: [.atomic])

        let store = await UserProfileStore(
            filename: "profile.json",
            legacySubjectsFilename: "legacy.json",
            directory: dir,
            seedSampleData: false
        )

        await #expect(store.profile.subjects.count == 2)
        await #expect(store.profile.subjects.map(\.code) == ["HIST", "BIO"])
    }

}
