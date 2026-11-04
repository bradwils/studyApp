import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
@Suite("FieldKind / FieldContent")
struct FieldKindTests {

	// MARK: - defaultContent

	@Test("Text defaults to an empty string")
	func textDefault() {
		#expect(FieldKind.text.defaultContent.textValue == "")
	}

	@Test("Number defaults to zero")
	func numberDefault() {
		#expect(FieldKind.number.defaultContent.numberValue == 0)
	}

	@Test("Time defaults to zero seconds")
	func timeDefault() {
		#expect(FieldKind.time.defaultContent.timeValue == 0)
	}

	@Test("Date defaults to now")
	func dateDefault() throws {
		let date = try #require(FieldKind.date.defaultContent.dateValue)
		#expect(abs(date.timeIntervalSinceNow) < 1)
	}

	@Test("Dropdown defaults to its first option")
	func dropdownDefaultsToFirstOption() {
		#expect(FieldKind.dropdown(options: ["Easy", "Hard"]).defaultContent.dropdownValue == "Easy")
	}

	@Test("Dropdown with no options defaults to an empty string")
	func dropdownWithoutOptionsDefault() {
		#expect(FieldKind.dropdown(options: []).defaultContent.dropdownValue == "")
	}

	// MARK: - Codable (this is what SwiftData persists)

	@Test("Dropdown kind keeps its options through encode/decode")
	func dropdownKindRoundTrips() throws {
		let data = try JSONEncoder().encode(FieldKind.dropdown(options: ["Easy", "Hard"]))
		let decoded = try JSONDecoder().decode(FieldKind.self, from: data)

		#expect(decoded.dropdownOptions == ["Easy", "Hard"])
	}

	@Test("Payload-less kinds keep their identity through encode/decode")
	func simpleKindsRoundTrip() throws {
		let kinds: [FieldKind] = [.text, .number, .date, .time]

		for kind in kinds {
			let decoded = try JSONDecoder().decode(FieldKind.self, from: JSONEncoder().encode(kind))
			#expect(FieldKindChoice(decoded) == FieldKindChoice(kind))
		}
	}

	@Test("Content payloads survive encode/decode")
	func contentRoundTrips() throws {
		let when = Date(timeIntervalSince1970: 1_800_000_000)
		let contents: [FieldContent] = [.text("hello"), .number(4.5), .date(when), .time(90), .dropdown("Hard")]

		let decoded = try contents.map {
			try JSONDecoder().decode(FieldContent.self, from: JSONEncoder().encode($0))
		}

		#expect(decoded[0].textValue == "hello")
		#expect(decoded[1].numberValue == 4.5)
		#expect(decoded[2].dateValue == when)
		#expect(decoded[3].timeValue == 90)
		#expect(decoded[4].dropdownValue == "Hard")
	}
}

@MainActor
@Suite("FieldDefinition / FieldValue models")
struct FieldDefinitionAndValueTests {

	// MARK: - Defaults and persistence

	@Test("Definition is enabled by default")
	func definitionEnabledByDefault() {
		#expect(FieldDefinition(name: "Pages", kind: .number, order: 0).isEnabled)
	}

	@Test("Dropdown definition keeps its options through the store")
	func definitionPersistsKind() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(FieldDefinition(name: "Difficulty", kind: .dropdown(options: ["Easy", "Hard"]), order: 2, isEnabled: false))
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<FieldDefinition>()).first)
		#expect(fetched.name == "Difficulty")
		#expect(fetched.kind.dropdownOptions == ["Easy", "Hard"])
		#expect(fetched.order == 2)
		#expect(fetched.isEnabled == false)
	}

	@Test("Value content survives the store")
	func valuePersistsContent() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(FieldValue(content: .number(12)))
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<FieldValue>()).first)
		#expect(fetched.content.numberValue == 12)
	}

	// MARK: - Relationships

	@Test("Linking a value to an item and definition is visible from both parents")
	func valueInverses() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let (item, definition, value) = try insertLinkedValue(in: context)

		#expect(item.values.count == 1)
		#expect(definition.values.count == 1)
		#expect(value.item?.id == item.id)
		#expect(value.definition?.name == definition.name)
	}

	@Test("Deleting an item cascades to its values but keeps the definition")
	func deletingItemCascadesToValues() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let (item, definition, _) = try insertLinkedValue(in: context)

		context.delete(item)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<FieldValue>()) == 0)
		#expect(try context.fetchCount(FetchDescriptor<FieldDefinition>()) == 1)
		#expect(definition.values.isEmpty)
	}

	@Test("Deleting a definition cascades to its values but keeps the item")
	func deletingDefinitionCascadesToValues() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let (item, definition, _) = try insertLinkedValue(in: context)

		context.delete(definition)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<FieldValue>()) == 0)
		#expect(try context.fetchCount(FetchDescriptor<StudyItem>()) == 1)
		#expect(item.values.isEmpty)
	}

	@Test("Deleting a single value keeps both parents")
	func deletingValueKeepsParents() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let (item, definition, value) = try insertLinkedValue(in: context)

		context.delete(value)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<StudyItem>()) == 1)
		#expect(try context.fetchCount(FetchDescriptor<FieldDefinition>()) == 1)
		#expect(item.values.isEmpty)
		#expect(definition.values.isEmpty)
	}

	@Test("One definition can hold a value for many items")
	func definitionSharedAcrossItems() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 0)
		context.insert(definition)

		for name in ["A", "B", "C"] {
			let item = StudyItem(taskName: name)
			let value = FieldValue(content: .number(1))
			context.insert(item)
			context.insert(value)
			value.definition = definition
			value.item = item
		}
		try context.save()

		#expect(definition.values.count == 3)
	}

	// MARK: - Helpers

	private func insertLinkedValue(in context: ModelContext) throws -> (StudyItem, FieldDefinition, FieldValue) {
		let item = StudyItem(taskName: "Read chapter")
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 0)
		let value = FieldValue(content: .number(12))
		context.insert(item)
		context.insert(definition)
		context.insert(value)
		value.item = item
		value.definition = definition
		try context.save()
		return (item, definition, value)
	}
}
