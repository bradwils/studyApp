import Foundation
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct StudyItemsV2DebugTests {
    @Test("Adding an item saves it without caller-managed saves")
    func addsItem() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let item = StudyItemDebugVM().addItem(context: writer)

        let reader = makeStudyItemTestContext(container)
        let items = try reader.fetch(FetchDescriptor<StudyItem>())
        #expect(items.count == 1)
        #expect(items.first?.id == item.id)
        #expect(items.first?.taskName == "New item")
    }

    @Test("Adding a field seeds only the slot chosen by its definition", arguments: FieldKind.allCases)
    func seedsValue(kind: FieldKind) throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let definition = FieldDefinition(name: "Custom", kind: kind, options: ["First", "Second"])
        let item = StudyItem(taskName: "Task")
        item.updatedAt = .distantPast
        writer.insert(definition)
        writer.insert(item)
        let before = Date.now
        StudyItemDebugVM().addValue(for: definition, to: item, context: writer)
        let after = Date.now

        let reader = makeStudyItemTestContext(container)
        let value = try #require(reader.fetch(FetchDescriptor<FieldValue>()).first)
        #expect(value.textValue == (kind == .text ? "" : kind == .dropdown ? "First" : nil))
        #expect(value.numberValue == (kind == .number ? 0 : nil))
        #expect(value.timeValue == (kind == .time ? 0 : nil))
        if kind == .date {
            let date = try #require(value.dateValue)
            #expect((before...after).contains(date))
        } else {
            #expect(value.dateValue == nil)
        }
        #expect(value.item?.id == item.id)
        #expect(value.definition?.name == "Custom")
        #expect(value.item?.values.count == 1)
        #expect(value.definition?.values.count == 1)
        let storedItem = try #require(value.item)
        #expect((before...after).contains(storedItem.updatedAt))
    }

    @Test("An empty dropdown seeds an empty selection")
    func seedsEmptyDropdown() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let item = StudyItem(taskName: "Task")
        let definition = FieldDefinition(name: "Choice", kind: .dropdown)
        writer.insert(item)
        writer.insert(definition)
        StudyItemDebugVM().addValue(for: definition, to: item, context: writer)

        let reader = makeStudyItemTestContext(container)
        let value = try #require(reader.fetch(FetchDescriptor<FieldValue>()).first)
        #expect(value.textValue == "")
    }

    @Test("Deleting one value preserves its item, definition, and other values")
    func deletesValue() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let item = StudyItem(taskName: "Task")
        let definition = FieldDefinition(name: "Notes", kind: .text)
        writer.insert(item)
        writer.insert(definition)
        let vm = StudyItemDebugVM()
        vm.addValue(for: definition, to: item, context: writer)
        vm.addValue(for: definition, to: item, context: writer)
        let removed = try #require(item.values.first)
        let removedID = removed.persistentModelID
        item.updatedAt = .distantPast
        let before = Date.now
        vm.delete(removed, from: item, context: writer)
        let after = Date.now

        let reader = makeStudyItemTestContext(container)
        let values = try reader.fetch(FetchDescriptor<FieldValue>())
        let storedItem = try #require(reader.fetch(FetchDescriptor<StudyItem>()).first)
        let storedDefinition = try #require(reader.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(values.count == 1)
        #expect(values.first?.persistentModelID != removedID)
        #expect(storedItem.id == item.id)
        #expect(storedItem.values.count == 1)
        #expect(storedDefinition.values.count == 1)
        #expect((before...after).contains(storedItem.updatedAt))
    }

    @Test("Deleting all items removes their values and preserves shared references")
    func deletesAllItemsAndOwnedValues() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let subject = Subject(name: "Physics", code: "PHY")
        let tag = studyApp.Tag(name: "Revision")
        let definition = FieldDefinition(name: "Notes", kind: .text)
        writer.insert(subject)
        writer.insert(tag)
        writer.insert(definition)
        let vm = StudyItemDebugVM()
        for name in ["First", "Second"] {
            let item = StudyItem(taskName: name, subject: subject)
            writer.insert(item)
            item.tag = tag
            vm.addValue(for: definition, to: item, context: writer)
        }
        vm.deleteAll(context: writer)

        let reader = makeStudyItemTestContext(container)
        #expect(try reader.fetchCount(FetchDescriptor<StudyItem>()) == 0)
        #expect(try reader.fetchCount(FetchDescriptor<FieldValue>()) == 0)
        #expect(try reader.fetchCount(FetchDescriptor<FieldDefinition>()) == 1)
        let storedSubject = try #require(reader.fetch(FetchDescriptor<Subject>()).first)
        let storedTag = try #require(reader.fetch(FetchDescriptor<studyApp.Tag>()).first)
        let storedDefinition = try #require(reader.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(storedSubject.items.isEmpty)
        #expect(storedTag.items.isEmpty)
        #expect(storedDefinition.values.isEmpty)
    }

    @Test("Status and subject edits touch the item and refresh the subject snapshot")
    func editsItem() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let first = Subject(name: "Old", code: "OLD")
        let second = Subject(name: "New", code: "NEW")
        let item = StudyItem(taskName: "Task", subject: first)
        writer.insert(first)
        writer.insert(second)
        writer.insert(item)
        let vm = StudyItemDebugVM()
        item.updatedAt = .distantPast
        let before = Date.now
        vm.setStatus(.inProgress, on: item)
        #expect((before...Date.now).contains(item.updatedAt))
        item.updatedAt = .distantPast
        vm.setSubject(second, on: item)
        let after = Date.now
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let stored = try #require(reader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(stored.status == .inProgress)
        #expect(stored.subject?.id == second.id)
        #expect(stored.subjectName == "New")
        #expect((before...after).contains(stored.updatedAt))
        #expect(stored.subject?.items.map(\.id) == [item.id])

        item.updatedAt = .distantPast
        vm.setSubject(nil, on: item)
        try writer.save()
        let clearedReader = makeStudyItemTestContext(container)
        let cleared = try #require(clearedReader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(cleared.subject == nil)
        #expect(cleared.subjectName == nil)
        #expect(cleared.updatedAt > .distantPast)
    }
}
