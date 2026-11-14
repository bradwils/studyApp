import Foundation
import SwiftData
import Testing
@testable import studyApp

// Isolated stores with autosave and CloudKit disabled expose missing saves without touching app data.
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
        let otherSubjectID = otherSubject.id
        try context.save()
        try expectGraphCounts(makeContext(container), sessions: 3, children: 3)

        SubjectsEditorVM().removeSubject(subject, context: context)
        try context.save()

        let reader = makeContext(container)
        let subjects = try reader.fetch(FetchDescriptor<Subject>())
        #expect(subjects.map(\.id) == [otherSubjectID])
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
        #expect(retained.subject?.id == otherSubjectID)
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

    @Test("Session deletion preserves active sessions", arguments: [false, true])
    func deletingSessionsPreservesActiveGraph(deleteAll: Bool) throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        let active = insertSession(subject: subject, label: "Active", context: context)
        active.endedAt = nil
        let ended = insertSession(subject: subject, label: "Ended", context: context)
        let activeID = active.id
        try context.save()

        let viewer = SessionViewerViewModel()
        if deleteAll {
            viewer.removeAllSessions(context: context)
        } else {
            viewer.deleteSessions([active, ended], context: context)
        }

        let reader = makeContext(container)
        let stored = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(stored.map(\.id) == [activeID])
        #expect(stored.first?.endedAt == nil)
        #expect(stored.first?.subject?.id == subject.id)
        #expect(stored.first?.location?.locationLabel == "Active")
        try expectGraphCounts(reader, sessions: 1, children: 1)
        #expect(!context.hasChanges)
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
        vm.selectSubject(subject)
        vm.startSession(context: context)
        let active = try #require(vm.activeSession)
        active.breaks = [StudyBreak(startedAt: active.startedAt, endedAt: active.startedAt)]
        active.location = SessionLocation(locationLabel: "Cancelled")
        #expect(vm.startFocusTarget(duration: 300))
        try context.save()
        try expectGraphCounts(makeContext(container), sessions: 2, children: 2)

        vm.cancelSession(context: context)

        let reader = makeContext(container)
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(sessions.map(\.id) == [previousID])
        #expect(sessions.first?.subject?.id == subjectID)
        #expect(sessions.first?.location?.locationLabel == "Previous")
        #expect(try reader.fetch(FetchDescriptor<Subject>()).map(\.id) == [subjectID])
        try expectGraphCounts(reader, sessions: 1, children: 1)
        #expect(vm.activeSession == nil)
        #expect(vm.focusTarget == nil)
        #expect(vm.phase == .idle)
    }

    @Test("Completion saves metadata and relationships without relying on autosave")
    func completingSessionSavesGraph() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        context.insert(subject)
        let subjectID = subject.id
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        var current = startedAt
        let vm = StudyTrackingViewModel(now: { current })
        vm.selectSubject(subject)
        vm.startSession(context: context)
        let session = try #require(vm.activeSession)
        #expect(session.endedAt == nil)
        let sessionID = session.id
        session.notes = "Revision"
        session.studyScore = 8
        session.friends = ["friend"]
        session.location = SessionLocation(locationLabel: "Library")
        current.addTimeInterval(60)
        vm.pauseSession(context: context)
        current.addTimeInterval(30)
        vm.resumeSession(context: context)
        vm.addInterruption()
        #expect(vm.startFocusTarget(duration: 300))
        current.addTimeInterval(30)

        vm.finishSession(context: context)

        let reader = makeContext(container)
        let stored = try #require(try reader.fetch(FetchDescriptor<StudySession>()).first)
        let endedAt = try #require(stored.endedAt)
        #expect(stored.id == sessionID)
        #expect(stored.startedAt == startedAt)
        #expect(endedAt == current)
        #expect(stored.subject?.id == subjectID)
        #expect(stored.subjectName == "Physics")
        #expect(stored.notes == "Revision")
        #expect(stored.studyScore == 8)
        #expect(stored.friends == ["friend"])
        #expect(stored.interruptionCount == 1)
        #expect(stored.totalBreakDuration == 30)
        #expect(stored.totalActiveDuration == endedAt.timeIntervalSince(startedAt) - 30)
        #expect(stored.breaks?.first?.duration == 30)
        #expect(stored.sections?.map(\.duration).sorted() == [30, 60])
        #expect(stored.location?.locationLabel == "Library")
        #expect(try reader.fetchCount(FetchDescriptor<StudySession>()) == 1)
        #expect(try reader.fetchCount(FetchDescriptor<StudyBreak>()) == 1)
        #expect(try reader.fetchCount(FetchDescriptor<StudySection>()) == 2)
        #expect(try reader.fetchCount(FetchDescriptor<SessionLocation>()) == 1)
        #expect(!context.hasChanges)
        #expect(vm.activeSession == nil)
        #expect(vm.focusTarget == nil)
        #expect(vm.phase == .idle)
    }

    @Test("Finishing without an active session preserves existing history")
    func finishingWithoutActiveSessionPreservesHistory() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        let subject = Subject(name: "Physics", code: "PHYS")
        let previous = insertSession(subject: subject, label: "Previous", context: context)
        let previousID = previous.id
        try context.save()
        previous.notes = "Unsaved edit"
        let vm = StudyTrackingViewModel()

        vm.finishSession(context: context)
        vm.cancelSession(context: context)

        let reader = makeContext(container)
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(sessions.map(\.id) == [previousID])
        #expect(sessions.first?.notes == "Previous")
        #expect(context.hasChanges)
        try expectGraphCounts(reader, sessions: 1, children: 1)
    }

    @Test("Session graphs and their deletion survive reopening a disk store")
    func savedGraphAndDeletionSurviveReopeningStore() throws {
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
            insertSession(id: sessionID, subject: subject, label: "Persisted", context: context)
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
            SessionViewerViewModel().deleteSessions([session], context: reader)
        }

        try autoreleasepool {
            let reopened = try makeContainer(at: storeURL)
            let reader = makeContext(reopened)
            let subjects = try reader.fetch(FetchDescriptor<Subject>())
            #expect(subjects.map(\.id) == [subjectID])
            #expect(subjects.first?.sessions.isEmpty == true)
            try expectGraphCounts(reader, sessions: 0, children: 0)
        }
    }

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

    private func makeContext(_ container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    @discardableResult
    private func insertSession(id: UUID = UUID(), subject: Subject, label: String,
                               context: ModelContext) -> StudySession {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let session = StudySession(id: id, subject: subject, subjectName: subject.name, startedAt: start,
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
