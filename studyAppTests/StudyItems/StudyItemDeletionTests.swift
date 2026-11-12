import Testing
import SwiftData
@testable import studyApp

@Suite("StudyItem deletion rules")
@MainActor
struct StudyItemDeletionTests {

	@Test("X1 deleting an item deletes its values but keeps definitions and tags")
	func deletingItemCascadesToValues() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let definition = Fixtures.definition(in: context)
		let tag = Fixtures.tag(in: context)
		let value = Fixtures.value(item: item, definition: definition, in: context)
		value.tags.append(tag)
		item.tags.append(tag)
		try context.save()

		context.delete(item)
		try context.save()

		#expect(try context.count(StudyItem.self) == 0)
		#expect(try context.count(FieldValue.self) == 0)
		#expect(try context.count(FieldDefinition.self) == 1)
		#expect(try context.count(Tag.self) == 1)
	}

	@Test("X2 deleting a definition deletes its values but keeps items")
	func deletingDefinitionCascadesToValues() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let definition = Fixtures.definition(in: context)
		_ = Fixtures.value(item: item, definition: definition, in: context)
		_ = Fixtures.value(item: item, definition: definition, in: context)
		try context.save()

		context.delete(definition)
		try context.save()

		#expect(try context.count(FieldDefinition.self) == 0)
		#expect(try context.count(FieldValue.self) == 0)
		#expect(try context.count(StudyItem.self) == 1)
		#expect(item.values.isEmpty)
	}

	@Test("X3 deleting a tag keeps items and field values and clears their tags")
	func deletingTagNullifiesReferences() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let value = Fixtures.value(item: item, in: context)
		let tag = Fixtures.tag(in: context)
		item.tags.append(tag)
		value.tags.append(tag)
		try context.save()

		context.delete(tag)
		try context.save()

		#expect(try context.count(Tag.self) == 0)
		#expect(try context.count(StudyItem.self) == 1)
		#expect(try context.count(FieldValue.self) == 1)
		#expect(item.tags.isEmpty)
		#expect(value.tags.isEmpty)
	}

	@Test("X4 deleting an item keeps the tag and removes the item from tag.items")
	func deletingItemKeepsTag() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let tag = Fixtures.tag(in: context)
		item.tags.append(tag)
		try context.save()
		let itemID = item.persistentModelID

		context.delete(item)
		try context.save()

		#expect(try context.count(Tag.self) == 1)
		#expect(!tag.items.modelIDs.contains(itemID))
	}

	@Test("X5 deleting a subject keeps the item and its subjectName")
	func deletingSubjectKeepsItem() throws {
		let context = try TestContainer.make()
		let subject = Fixtures.subject("Maths", in: context)
		let item = Fixtures.item(in: context, subject: subject)
		try context.save()

		context.delete(subject)
		try context.save()

		#expect(try context.count(Subject.self) == 0)
		#expect(try context.count(StudyItem.self) == 1)
		#expect(item.subject == nil)
		#expect(item.subjectName == "Maths")
	}

	@Test("X6 deleting one value keeps its item and definition")
	func deletingValueKeepsParents() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let definition = Fixtures.definition(in: context)
		let doomed = Fixtures.value(item: item, definition: definition, in: context)
		let kept = Fixtures.value(item: item, definition: definition, in: context)
		try context.save()
		let doomedID = doomed.persistentModelID

		context.delete(doomed)
		try context.save()

		#expect(try context.count(FieldValue.self) == 1)
		#expect(try context.count(StudyItem.self) == 1)
		#expect(try context.count(FieldDefinition.self) == 1)
		#expect(item.values.modelIDs == [kept.persistentModelID])
		#expect(definition.values.modelIDs == [kept.persistentModelID])
		#expect(!item.values.modelIDs.contains(doomedID))
	}

	@Test("X7 deleting every item leaves no values but keeps definitions and tags")
	func deletingAllItemsClearsValues() throws {
		let context = try TestContainer.make()
		let definitions = [
			Fixtures.definition("Pages", type: .number, order: 0, in: context),
			Fixtures.definition("Outline", order: 1, in: context)
		]
		let tags = [Fixtures.tag("urgent", in: context), Fixtures.tag("exam", in: context)]
		let items = (1...3).map { Fixtures.item("Item \($0)", in: context) }
		for item in items {
			item.tags = tags
			for definition in definitions {
				let value = Fixtures.value(item: item, definition: definition, in: context)
				value.tags.append(tags[0])
			}
		}
		try context.save()
		#expect(try context.count(FieldValue.self) == 6)

		for item in items { context.delete(item) }
		try context.save()

		#expect(try context.count(StudyItem.self) == 0)
		#expect(try context.count(FieldValue.self) == 0)
		#expect(try context.count(FieldDefinition.self) == 2)
		#expect(try context.count(Tag.self) == 2)
	}
}
