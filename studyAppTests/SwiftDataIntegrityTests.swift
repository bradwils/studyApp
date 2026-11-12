import Foundation
import SwiftData
import Testing
@testable import studyApp

/// Tests persistence and relationship integrity independently of the app's shared store and autosave.
///
/// ## Declaration
///
/// ```swift
/// @MainActor struct SwiftDataIntegrityTests
/// ```
///
/// Each test owns its SwiftData container. Deletion, cancellation, and completion
/// checks read saved records through a fresh context; disk coverage releases the
/// writer before reopening a temporary store.
///
/// > Important: Autosave and CloudKit are disabled so missing explicit saves are
/// > exposed without touching app data. Temporary disk files are removed afterward.
@MainActor
struct SwiftDataIntegrityTests {
    @Test("Deleting a subject preserves its sessions and their owned records")
    func deletingSubjectPreservesHistory() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        let otherSubject = Subject(name: "Math", code: "MATH")
        let first = insertSession(subject: subject, label: "First", context: context)
        let second = insertSession(subject: subject, label: "Second", context: context)
        let other = insertSession(subject: otherSubject, label: "Other", context: context)
        let deletedIDs = Set([first.id, second.id])
        let otherID = other.id
        let subjectID = otherSubject.id
        try context.save()
        try expectGraphCounts(makeContext(container), sessions: 3, children: 3)

        SubjectsEditorVM().removeSubject(subject, context: context)
        try context.save()

        let reader = makeContext(container)
        let subjects = try reader.fetch(FetchDescriptor<Subject>())
        #expect(subjects.map(\.id) == [subjectID])
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(Set(sessions.map(\.id)) == deletedIDs.union([otherID]))
        for session in sessions where deletedIDs.contains(session.id) {
            #expect(session.subject == nil)
            #expect(session.subjectName == "Physics")
            #expect(session.breaks?.count == 1)
            #expect(session.sections?.count == 1)
            #expect(session.location != nil)
        }
        let retained = try #require(sessions.first { $0.id == otherID })
        #expect(retained.subject?.id == subjectID)
        #expect(Set(subjects.first?.sessions.map(\.id) ?? []) == [otherID])
        try expectGraphCounts(reader, sessions: 3, children: 3)
    }

    @Test("Session deletion cascades only to owned records", arguments: [false, true])
    func deletingSessionsPreservesUnrelatedRecords(deleteAll: Bool) throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        let first = insertSession(subject: subject, label: "Delete", context: context)
        let second = insertSession(subject: subject, label: "Keep", context: context)
        let retainedID = second.id
        let subjectID = subject.id
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(StudyBreak(startedAt: timestamp, endedAt: timestamp.addingTimeInterval(10)))
        context.insert(StudySection(startedAt: timestamp, endedAt: timestamp.addingTimeInterval(20)))
        context.insert(SessionLocation(locationLabel: "Unrelated"))
        try context.save()
        try expectGraphCounts(makeContext(container), sessions: 2, children: 3)

        let viewer = SessionViewerViewModel()
        if deleteAll {
            viewer.removeAllSessions(context: context)
        } else {
            viewer.deleteSessions([first], context: context)
        }

        let reader = makeContext(container)
        let subjects = try reader.fetch(FetchDescriptor<Subject>())
        #expect(subjects.map(\.id) == [subjectID])
        let expectedIDs: Set<UUID> = deleteAll ? [] : [retainedID]
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(Set(sessions.map(\.id)) == expectedIDs)
        #expect(Set(subjects.first?.sessions.map(\.id) ?? []) == expectedIDs)
        try expectGraphCounts(reader, sessions: deleteAll ? 0 : 1, children: deleteAll ? 1 : 2)
        let locations = try reader.fetch(FetchDescriptor<SessionLocation>())
        #expect(locations.contains { $0.locationLabel == "Unrelated" })
        let breaks = try reader.fetch(FetchDescriptor<StudyBreak>())
        let sections = try reader.fetch(FetchDescriptor<StudySection>())
        #expect(breaks.contains { $0.duration == 10 })
        #expect(sections.contains { $0.duration == 20 })
        if !deleteAll {
            let retained = try #require(sessions.first)
            #expect(retained.notes == "Keep")
            #expect(retained.subject?.id == subjectID)
            #expect(retained.breaks?.count == 1)
            #expect(retained.sections?.count == 1)
            #expect(retained.location?.locationLabel == "Keep")
        }
    }

    @Test("Cancellation removes the active graph and preserves existing history")
    func cancellingSessionPreservesHistory() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        let previous = insertSession(subject: subject, label: "Previous", context: context)
        let previousID = previous.id
        let subjectID = subject.id
        try context.save()
        let vm = StudyTrackingViewModel()
        vm.selectedSubject = subject
        vm.startSession(ctx: context)
        let active = try #require(vm.activeSession)
        active.breaks = [StudyBreak(startedAt: active.startedAt, endedAt: active.startedAt)]
        active.sections = [StudySection(startedAt: active.startedAt, endedAt: active.startedAt)]
        active.location = SessionLocation(locationLabel: "Cancelled")
        vm.startPureFocusSession(300)
        vm.focusLockEnabled = true
        try context.save()
        try expectGraphCounts(makeContext(container), sessions: 2, children: 2)

        vm.cancelActiveSession(ctx: context)

        let reader = makeContext(container)
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(sessions.map(\.id) == [previousID])
        #expect(sessions.first?.subject?.id == subjectID)
        #expect(sessions.first?.location?.locationLabel == "Previous")
        #expect(try reader.fetch(FetchDescriptor<Subject>()).map(\.id) == [subjectID])
        try expectGraphCounts(reader, sessions: 1, children: 1)
        #expect(vm.activeSession == nil)
        #expect(vm.ssw == nil)
        #expect(vm.activePureFocusSession == nil)
        #expect(!vm.focusLockEnabled)
    }

    @Test("Completion saves metadata and relationships without relying on autosave")
    func completingSessionSavesGraph() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        context.insert(subject)
        let subjectID = subject.id
        let vm = StudyTrackingViewModel()
        vm.selectedSubject = subject
        vm.startSession(ctx: context)
        let session = try #require(vm.activeSession)
        let sessionID = session.id
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        session.startedAt = startedAt
        session.notes = "Revision"
        session.studyScore = 8
        session.friends = ["friend"]
        session.location = SessionLocation(locationLabel: "Library")
        vm.studyBreaks = [StudyBreak(startedAt: startedAt.addingTimeInterval(60),
                                    endedAt: startedAt.addingTimeInterval(90))]
        vm.studySections = [StudySection(startedAt: startedAt, endedAt: startedAt.addingTimeInterval(60))]
        vm.addInterruption()
        vm.startPureFocusSession(300)
        vm.focusLockEnabled = true
        let beforeEnding = Date.now

        vm.endSession(context: context)

        let afterEnding = Date.now
        let reader = makeContext(container)
        let stored = try #require(try reader.fetch(FetchDescriptor<StudySession>()).first)
        let endedAt = try #require(stored.endedAt)
        #expect(stored.id == sessionID)
        #expect(stored.startedAt == startedAt)
        #expect(endedAt >= beforeEnding && endedAt <= afterEnding)
        #expect(stored.subject?.id == subjectID)
        #expect(stored.subjectName == "Physics")
        #expect(stored.notes == "Revision")
        #expect(stored.studyScore == 8)
        #expect(stored.friends == ["friend"])
        #expect(stored.interruptionCount == 1)
        #expect(stored.totalBreakDuration == 30)
        #expect(stored.breaks?.first?.duration == 30)
        #expect(stored.sections?.first?.duration == 60)
        #expect(stored.location?.locationLabel == "Library")
        try expectGraphCounts(reader, sessions: 1, children: 1)
        #expect(!context.hasChanges)
        #expect(vm.activeSession == nil)
        #expect(vm.ssw == nil)
        #expect(vm.activePureFocusSession == nil)
        #expect(!vm.focusLockEnabled)
    }

    @Test("Subjects and completed session graphs survive reopening a disk store")
    func savedGraphSurvivesReopeningStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Integrity.store")
        let subjectID = UUID()
        let sessionID = UUID()
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)

        // Release the writer, its models, and its container before reopening the store.
        try autoreleasepool {
            let container = try makeContainer(at: storeURL)
            let context = makeContext(container)
            let subject = Subject(id: subjectID, name: "Physics", code: "PHYS", createdAt: startedAt)
            let session = insertSession(subject: subject, label: "Persisted", context: context)
            session.id = sessionID
            try context.save()
        }

        try autoreleasepool {
            let reopened = try makeContainer(at: storeURL)
            let reader = makeContext(reopened)
            let subjects = try reader.fetch(FetchDescriptor<Subject>())
            #expect(subjects.count == 1)
            let subject = try #require(subjects.first)
            #expect(subject.id == subjectID)
            #expect(subject.name == "Physics")
            #expect(subject.code == "PHYS")
            #expect(subject.createdAt == startedAt)
            #expect(subject.sessions.map(\.id) == [sessionID])
            let session = try #require(try reader.fetch(FetchDescriptor<StudySession>()).first)
            #expect(session.id == sessionID)
            #expect(session.subject?.id == subjectID)
            #expect(session.subjectName == "Physics")
            #expect(session.startedAt == startedAt)
            #expect(session.endedAt == startedAt.addingTimeInterval(120))
            #expect(session.totalActiveDuration == 90)
            #expect(session.totalBreakDuration == 30)
            #expect(session.notes == "Persisted")
            #expect(session.studyScore == 8)
            #expect(session.friends == ["friend"])
            #expect(session.interruptionCount == 2)
            #expect(session.breaks?.first?.startedAt == startedAt.addingTimeInterval(60))
            #expect(session.breaks?.first?.duration == 30)
            #expect(session.sections?.first?.startedAt == startedAt)
            #expect(session.sections?.first?.duration == 60)
            #expect(session.location?.locationLabel == "Persisted")
            #expect(session.location?.latitude == -33.86)
            #expect(session.location?.longitude == 151.21)
            try expectGraphCounts(reader, sessions: 1, children: 1)
        }
    }

    /// Creates an isolated store in memory, or on disk when a URL is supplied, with CloudKit disabled.
    private func makeContainer(at storeURL: URL? = nil) throws -> ModelContainer {
        let schema = Schema([Subject.self, StudySession.self, StudyBreak.self,
                             StudySection.self, SessionLocation.self])
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Disables autosave so persistence assertions require an explicit save.
    private func makeContext(_ container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func insertSession(subject: Subject, label: String, context: ModelContext) -> StudySession {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let session = StudySession(subject: subject, subjectName: subject.name, startedAt: start,
                                   endedAt: start.addingTimeInterval(120), totalBreakDuration: 30,
                                   breaks: [StudyBreak(startedAt: start.addingTimeInterval(60),
                                                       endedAt: start.addingTimeInterval(90))],
                                   sections: [StudySection(startedAt: start, endedAt: start.addingTimeInterval(60))],
                                   friends: ["friend"],
                                   location: SessionLocation(latitude: -33.86, longitude: 151.21, locationLabel: label),
                                   studyScore: 8, notes: label, interruptionCount: 2)
        context.insert(session)
        return session
    }

    private func expectGraphCounts(_ context: ModelContext, sessions: Int, children: Int) throws {
        #expect(try context.fetchCount(FetchDescriptor<StudySession>()) == sessions)
        #expect(try context.fetchCount(FetchDescriptor<StudyBreak>()) == children)
        #expect(try context.fetchCount(FetchDescriptor<StudySection>()) == children)
        #expect(try context.fetchCount(FetchDescriptor<SessionLocation>()) == children)
    }
}
