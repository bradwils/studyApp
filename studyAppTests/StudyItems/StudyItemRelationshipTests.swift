import SwiftData
import Testing
@testable import studyApp

@MainActor
struct StudyItemsV2RelationshipTests {
    @Test("Deleting a subject or tag preserves its items and subject snapshot")
    func deletingReferencesNullifiesItems() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let subject = Subject(name: "Physics", code: "PHY")
        let tag = Tag(name: "Exam")
        let item = StudyItem(taskName: "Revise", subject: subject)
        writer.insert(subject)
        writer.insert(tag)
        writer.insert(item)
        item.tag = tag
        try writer.save()

        let initialReader = makeStudyItemTestContext(container)
        let storedSubject = try #require(initialReader.fetch(FetchDescriptor<Subject>()).first)
        let storedTag = try #require(initialReader.fetch(FetchDescriptor<Tag>()).first)
        #expect(storedSubject.items.map(\.id) == [item.id])
        #expect(storedTag.items.map(\.id) == [item.id])

        writer.delete(subject)
        writer.delete(tag)
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let stored = try #require(reader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(stored.id == item.id)
        #expect(stored.subject == nil)
        #expect(stored.tag == nil)
        #expect(stored.subjectName == "Physics")
        #expect(try reader.fetchCount(FetchDescriptor<Subject>()) == 0)
        #expect(try reader.fetchCount(FetchDescriptor<Tag>()) == 0)
    }

    @Test("Deleting an item cascades its values but preserves shared definitions")
    func deletingItemCascadesValues() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let definition = FieldDefinition(name: "Notes", kind: .text)
        let first = StudyItem(taskName: "Delete me")
        let second = StudyItem(taskName: "Keep me")
        writer.insert(definition)
        writer.insert(first)
        writer.insert(second)
        let vm = StudyItemDebugVM()
        vm.addValue(for: definition, to: first, context: writer)
        vm.addValue(for: definition, to: second, context: writer)

        vm.delete(first, context: writer)

        let reader = makeStudyItemTestContext(container)
        let items = try reader.fetch(FetchDescriptor<StudyItem>())
        let values = try reader.fetch(FetchDescriptor<FieldValue>())
        let storedDefinition = try #require(reader.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(items.map(\.id) == [second.id])
        #expect(values.count == 1)
        #expect(values.first?.item?.id == second.id)
        #expect(storedDefinition.values.count == 1)
        #expect(storedDefinition.values.first?.item?.id == second.id)
    }

    @Test("Deleting a definition cascades its values across items without deleting items")
    func deletingDefinitionCascadesValues() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let removed = FieldDefinition(name: "Remove", kind: .text)
        let kept = FieldDefinition(name: "Keep", kind: .number)
        let first = StudyItem(taskName: "First")
        let second = StudyItem(taskName: "Second")
        writer.insert(removed)
        writer.insert(kept)
        writer.insert(first)
        writer.insert(second)
        let vm = StudyItemDebugVM()
        vm.addValue(for: removed, to: first, context: writer)
        vm.addValue(for: removed, to: second, context: writer)
        vm.addValue(for: kept, to: first, context: writer)

        FieldDefinitionFormVM().delete(removed, context: writer)

        let reader = makeStudyItemTestContext(container)
        let items = try reader.fetch(FetchDescriptor<StudyItem>())
        let definitions = try reader.fetch(FetchDescriptor<FieldDefinition>())
        let values = try reader.fetch(FetchDescriptor<FieldValue>())
        #expect(Set(items.map(\.id)) == Set([first.id, second.id]))
        #expect(definitions.count == 1)
        #expect(definitions.first?.name == "Keep")
        #expect(values.count == 1)
        #expect(values.first?.definition?.name == "Keep")
        #expect(items.first { $0.id == first.id }?.values.count == 1)
        #expect(items.first { $0.id == second.id }?.values.isEmpty == true)
    }
}
