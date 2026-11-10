import Foundation
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct StudyItemsV2ModelTests {
    @Test("New items have optional metadata and no field values")
    func defaults() {
        let before = Date.now
        let item = StudyItem(taskName: "Read chapter")
        let after = Date.now

        #expect(item.taskName == "Read chapter")
        #expect(item.status == .notStarted)
        #expect(item.notes == nil)
        #expect(item.dueDate == nil)
        #expect(item.priority == nil)
        #expect(item.completedAt == nil)
        #expect(item.subject == nil)
        #expect(item.subjectName == nil)
        #expect(item.tag == nil)
        #expect(item.values.isEmpty)
        #expect((before...after).contains(item.createdAt))
        #expect((before...after).contains(item.updatedAt))
        #expect(item.id != StudyItem(taskName: "Another item").id)
    }

    @Test("Items created completed receive an initial completion date")
    func completedAtInitialization() {
        let before = Date.now
        let item = StudyItem(taskName: "Finished", status: .completed)
        let after = Date.now

        #expect(item.completedAt.map { (before...after).contains($0) } == true)
    }

    @Test("Item metadata survives a save and a fresh context")
    func metadataRoundTrip() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let subject = Subject(name: "Mathematics", code: "MTH")
        let tag = studyApp.Tag(name: "Revision", color: .mango)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let item = StudyItem(
            taskName: "Integration", subject: subject, notes: "Exercises 1–5",
            status: .completed, dueDate: date, priority: .high
        )
        item.createdAt = date.addingTimeInterval(-100)
        item.updatedAt = date.addingTimeInterval(-50)
        item.completedAt = date.addingTimeInterval(-10)
        writer.insert(subject)
        writer.insert(tag)
        writer.insert(item)
        item.tag = tag
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let stored = try #require(reader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(stored.id == item.id)
        #expect(stored.taskName == "Integration")
        #expect(stored.notes == "Exercises 1–5")
        #expect(stored.status == .completed)
        #expect(stored.dueDate == date)
        #expect(stored.priority == .high)
        #expect(stored.createdAt == date.addingTimeInterval(-100))
        #expect(stored.updatedAt == date.addingTimeInterval(-50))
        #expect(stored.completedAt == date.addingTimeInterval(-10))
        #expect(stored.subject?.id == subject.id)
        #expect(stored.subjectName == "Mathematics")
        #expect(stored.tag?.key == "revision")
        #expect(stored.tag?.color == .mango)
    }

    @Test("Each field kind persists its live storage slot", arguments: FieldKind.allCases)
    func fieldValueRoundTrip(kind: FieldKind) throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let definition = FieldDefinition(name: "Custom field", kind: kind, options: ["First", "Second"])
        let item = StudyItem(taskName: "Exercise")
        let value = FieldValue()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        switch kind {
        case .text: value.textValue = "Explanation"
        case .number: value.numberValue = 12.5
        case .date: value.dateValue = date
        case .time: value.timeValue = 90.5
        case .dropdown: value.textValue = "Second"
        }
        writer.insert(definition)
        writer.insert(item)
        writer.insert(value)
        value.item = item
        value.definition = definition
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let stored = try #require(reader.fetch(FetchDescriptor<FieldValue>()).first)
        #expect(stored.definition?.kind == kind)
        #expect(stored.definition?.options == ["First", "Second"])
        #expect(stored.item?.id == item.id)
        #expect(stored.textValue == (kind == .text ? "Explanation" : kind == .dropdown ? "Second" : nil))
        #expect(stored.numberValue == (kind == .number ? 12.5 : nil))
        #expect(stored.dateValue == (kind == .date ? date : nil))
        #expect(stored.timeValue == (kind == .time ? 90.5 : nil))
        #expect(stored.item?.values.count == 1)
        #expect(stored.definition?.values.count == 1)
    }

    @Test("FieldValue starts with no populated slots")
    func emptyFieldValue() {
        let value = FieldValue()
        #expect(value.textValue == nil)
        #expect(value.numberValue == nil)
        #expect(value.dateValue == nil)
        #expect(value.timeValue == nil)
        #expect(value.item == nil)
        #expect(value.definition == nil)
    }

    @Test("Status and priority persist for every case", arguments: StudyItemStatus.allCases, StudyItemPriority.allCases)
    func enumPersistence(status: StudyItemStatus, priority: StudyItemPriority) throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        writer.insert(StudyItem(taskName: "Task", status: status, priority: priority))
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let item = try #require(reader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(item.status == status)
        #expect(item.priority == priority)
    }
}

struct StudyItemsV2CodableTests {
    @Test("Field kinds encode as payload-free strings", arguments: FieldKind.allCases)
    func fieldKindRoundTrip(kind: FieldKind) throws {
        let data = try JSONEncoder().encode(kind)
        #expect(String(decoding: data, as: UTF8.self) == "\"\(kind.rawValue)\"")
        #expect(try JSONDecoder().decode(FieldKind.self, from: data) == kind)
    }

    @Test("Unknown field kinds fail decoding")
    func unknownFieldKind() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(FieldKind.self, from: Data("\"unknown\"".utf8))
        }
    }
}
