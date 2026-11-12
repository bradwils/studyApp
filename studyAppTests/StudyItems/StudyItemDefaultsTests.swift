import Foundation
import Testing
@testable import studyApp

// Explicit list: allCases may be main-actor isolated (the app module defaults to MainActor), so keep it out of the nonisolated arguments expression
private let allFieldTypes: [FieldType] = [.text, .number, .date, .time, .dropdown]

@Suite("StudyItem defaults")
@MainActor
struct StudyItemDefaultsTests {

	@Test("D1 StudyItem init defaults")
	func itemDefaults() {
		let item = StudyItem(taskName: "Essay")

		#expect(item.status == .notStarted)
		#expect(item.completedAt == nil)
		#expect(abs(item.createdAt.timeIntervalSinceNow) < 1)
		#expect(abs(item.updatedAt.timeIntervalSinceNow) < 1)
		#expect(item.tags.isEmpty)
		#expect(item.values.isEmpty)
		#expect(item.priority == nil)
		#expect(item.dueDate == nil)
		#expect(item.notes == nil)
		#expect(item.subject == nil)
	}

	@Test("D2 completed status sets completedAt")
	func completedStatusSetsCompletedAt() throws {
		let item = StudyItem(taskName: "Essay", status: .completed)

		let completedAt = try #require(item.completedAt)
		#expect(abs(completedAt.timeIntervalSinceNow) < 1)
	}

	@Test("D3 FieldDefinition defaults")
	func definitionDefaults() {
		let definition = FieldDefinition(name: "Pages", type: .number, order: 0)

		#expect(definition.isEnabled)
		#expect(definition.options.isEmpty)
	}

	@Test("D4 argument list covers every FieldType")
	func fieldTypeListIsExhaustive() {
		#expect(Set(allFieldTypes) == Set(FieldType.allCases))
	}

	@Test("D4 FieldKind(type:options:).type round-trips", arguments: allFieldTypes)
	func kindTypeMatches(type: FieldType) {
		#expect(FieldKind(type: type, options: ["A"]).type == type)
	}

	@Test("D5 defaultContent per kind")
	func defaultContentPerKind() {
		let options = ["First", "Second"]
		func content(_ type: FieldType) -> FieldContent {
			FieldKind(type: type, options: options).config.defaultContent
		}

		if case .text(let text) = content(.text) {
			#expect(text == "")
		} else {
			Issue.record("text default is not .text")
		}

		if case .number(let number) = content(.number) {
			#expect(number == 0)
		} else {
			Issue.record("number default is not .number")
		}

		if case .time(let seconds) = content(.time) {
			#expect(seconds == 0)
		} else {
			Issue.record("time default is not .time")
		}

		if case .dropdown(let choice) = content(.dropdown) {
			#expect(choice == "First")
		} else {
			Issue.record("dropdown default is not .dropdown")
		}

		if case .date(let date) = content(.date) {
			#expect(abs(date.timeIntervalSinceNow) < 1)
		} else {
			Issue.record("date default is not .date")
		}
	}

	@Test("D6 dropdown with no options is invalid and defaults to an empty selection")
	func emptyDropdownIsInvalid() {
		let config = FieldKind(type: .dropdown, options: []).config

		#expect(!config.isValid)
		if case .dropdown(let choice) = config.defaultContent {
			#expect(choice == "")
		} else {
			Issue.record("dropdown default is not .dropdown")
		}
		#expect(FieldKind(type: .dropdown, options: ["A"]).config.isValid)
	}

	@Test("D6 every other kind is valid", arguments: [FieldType.text, .number, .date, .time])
	func otherKindsAreValid(type: FieldType) {
		#expect(FieldKind(type: type, options: []).config.isValid)
	}

	@Test("D7 Tag key is trimmed and lowercased, colour defaults to gray")
	func tagKeyAndDefaultColor() {
		let tag = Tag(name: "  MaThs \n")

		#expect(tag.key == "maths")
		#expect(Tag.key(for: "  MaThs \n") == tag.key)
		#expect(tag.color == .gray)
	}

	@Test("D8 BuiltInField storage keys are unique")
	func builtInStorageKeysAreUnique() {
		let keys = BuiltInField.allCases.map(\.storageKey)

		#expect(Set(keys).count == keys.count)
	}
}
