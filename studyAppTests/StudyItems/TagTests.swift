import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
@Suite("Tag model")
struct TagTests {

	// MARK: - Key normalisation

	@Test("Key is the lowercased name")
	func keyIsLowercased() {
		#expect(Tag(name: "Maths").key == "maths")
	}

	@Test("Init trims surrounding whitespace and newlines before building the key")
	func initTrims() {
		#expect(Tag(name: "  Maths \n").key == "maths")
	}

	// Documents current behaviour: key(for:) only lowercases. Trimming is the caller's job
	// (Tag.init and TagDebugVM both trim first), despite the property comment saying "lowercased + trimmed".
	@Test("key(for:) lowercases but does not trim")
	func keyForDoesNotTrim() {
		#expect(Tag.key(for: "Maths") == "maths")
		#expect(Tag.key(for: " Maths ") == " maths ")
	}

	@Test("New tag defaults to blue")
	func defaultColor() {
		#expect(Tag(name: "Exam").color == .blue)
	}

	@Test("Default name constant is stable")
	func defaultNameConstant() {
		#expect(Tag.defaultName == "default")
	}

	// MARK: - Persistence

	@Test("Every colour round-trips through the store", arguments: TagColor.allCases)
	func colorRoundTrips(color: TagColor) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(Tag(name: "Exam", color: color))
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<Tag>()).first)
		#expect(fetched.color == color)
	}

	// SwiftData treats a unique-attribute clash as an upsert, not an error, so the store
	// ends up with one row. TagDebugVM.addTag guards against this up front.
	@Test("Names differing only by case collapse to one stored tag")
	func uniqueKeyCollapsesCaseVariants() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(Tag(name: "Maths"))
		context.insert(Tag(name: "maths"))
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<Tag>()) == 1)
	}

	// MARK: - StudyItem relationship

	@Test("Tagging an item adds it to the tag's items (inverse is maintained)")
	func tagInverse() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let tag = Tag(name: "Exam")
		let item = StudyItem(taskName: "Revise")
		context.insert(tag)
		context.insert(item)

		item.tag = tag
		try context.save()

		#expect(tag.items.map(\.id) == [item.id])
	}

	@Test("Deleting a tag clears it from its items but keeps them")
	func deletingTagNullifiesItems() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let tag = Tag(name: "Exam")
		let item = StudyItem(taskName: "Revise")
		context.insert(tag)
		context.insert(item)
		item.tag = tag
		try context.save()

		context.delete(tag)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<StudyItem>()) == 1)
		#expect(item.tag == nil)
	}

	@Test("Deleting an item leaves its tag in place")
	func deletingItemKeepsTag() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let tag = Tag(name: "Exam")
		let item = StudyItem(taskName: "Revise")
		context.insert(tag)
		context.insert(item)
		item.tag = tag
		try context.save()

		context.delete(item)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<Tag>()) == 1)
		#expect(tag.items.isEmpty)
	}
}
