import Testing
import SwiftData
@testable import studyApp

@Suite("StudyItem relationships")
@MainActor
struct StudyItemRelationshipTests {

	@Test("R1 FieldValue inverse sets item")
	func valueAppendedToItemPointsBack() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let value = Fixtures.value(in: context)

		item.values.append(value)
		try context.save()

		#expect(value.item?.persistentModelID == item.persistentModelID)
		#expect(item.values.modelIDs.contains(value.persistentModelID))
	}

	@Test("R2 FieldValue.definition appears in definition.values")
	func valueDefinitionAppearsOnDefinition() throws {
		let context = try TestContainer.make()
		let definition = Fixtures.definition(in: context)
		let value = Fixtures.value(in: context)

		value.definition = definition
		try context.save()

		#expect(definition.values.modelIDs.contains(value.persistentModelID))
		#expect(value.definition?.persistentModelID == definition.persistentModelID)
	}

	@Test("R3 item and tag see each other from either side")
	func itemTagIsBidirectional() throws {
		let context = try TestContainer.make()
		let itemSide = Fixtures.item("Item side", in: context)
		let tagSide = Fixtures.item("Tag side", in: context)
		let tag = Fixtures.tag(in: context)

		itemSide.tags.append(tag)
		tag.items.append(tagSide)
		try context.save()

		#expect(tag.items.modelIDs.contains(itemSide.persistentModelID))
		#expect(tagSide.tags.modelIDs.contains(tag.persistentModelID))
	}

	@Test("R4 tags fan out across items and onto one item")
	func manyToManyCounts() throws {
		let context = try TestContainer.make()
		let items = (1...3).map { Fixtures.item("Item \($0)", in: context) }
		let shared = Fixtures.tag("shared", in: context)
		let extra = Fixtures.tag("extra", in: context)

		for item in items { item.tags.append(shared) }
		items[0].tags.append(extra)
		try context.save()

		#expect(shared.items.count == 3)
		#expect(extra.items.count == 1)
		#expect(items[0].tags.count == 2)
		#expect(items[1].tags.count == 1)
		#expect(items[2].tags.count == 1)
	}

	@Test("R5 init with subject sets subject, subjectName and subject.items")
	func initWithSubject() throws {
		let context = try TestContainer.make()
		let subject = Fixtures.subject("Maths", in: context)
		let item = Fixtures.item(in: context, subject: subject)
		try context.save()

		#expect(item.subject?.persistentModelID == subject.persistentModelID)
		#expect(item.subjectName == "Maths")
		#expect(subject.items.modelIDs.contains(item.persistentModelID))
	}

	@Test("R6 fieldValue and tag see each other after a fresh context")
	func fieldValueTagIsBidirectional() throws {
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		let value = Fixtures.value(in: context)
		let tag = Fixtures.tag(in: context)

		value.tags.append(tag)
		try context.save()

		#expect(tag.fieldValues.modelIDs.contains(value.persistentModelID))
		#expect(value.tags.modelIDs.contains(tag.persistentModelID))

		let fresh = ModelContext(container)
		let storedValue = try #require(fresh.fetch(FetchDescriptor<FieldValue>()).first)
		let storedTag = try #require(fresh.fetch(FetchDescriptor<studyApp.Tag>()).first)

		#expect(storedValue.persistentModelID == value.persistentModelID)
		#expect(storedTag.persistentModelID == tag.persistentModelID)
		#expect(storedTag.fieldValues.modelIDs == [storedValue.persistentModelID])
		#expect(storedValue.tags.modelIDs == [storedTag.persistentModelID])
	}
}
