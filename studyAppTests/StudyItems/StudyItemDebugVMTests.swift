import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
@Suite("StudyItemDebugVM")
struct StudyItemDebugVMTests {

	// MARK: - Create / delete

	@Test("addItem inserts and persists a placeholder item")
	func addItemPersists() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext

		let item = StudyItemDebugVM().addItem(context: context)

		let stored = try context.fetch(FetchDescriptor<StudyItem>())
		#expect(stored.map(\.id) == [item.id])
		#expect(item.taskName == "New item")
	}

	@Test("delete removes only the given item")
	func deleteRemovesOneItem() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = StudyItemDebugVM()
		let doomed = vm.addItem(context: context)
		let survivor = vm.addItem(context: context)

		vm.delete(doomed, context: context)

		#expect(try context.fetch(FetchDescriptor<StudyItem>()).map(\.id) == [survivor.id])
	}

	@Test("deleteAll clears items but not subjects")
	func deleteAllLeavesSubjects() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = StudyItemDebugVM()
		context.insert(Subject(name: "Maths", code: "MTH2"))
		_ = vm.addItem(context: context)
		_ = vm.addItem(context: context)

		vm.deleteAll(context: context)

		#expect(try context.fetchCount(FetchDescriptor<StudyItem>()) == 0)
		#expect(try context.fetchCount(FetchDescriptor<Subject>()) == 1)
	}

	// Batch delete(model:) may bypass the .cascade rule on StudyItem.values — if this fails,
	// deleteAll is leaving orphaned FieldValues behind.
	@Test("deleteAll also removes the items' field values")
	func deleteAllRemovesValues() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = StudyItemDebugVM()
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 0)
		context.insert(definition)
		let item = vm.addItem(context: context)
		vm.addValue(for: definition, to: item, context: context)

		vm.deleteAll(context: context)

		#expect(try context.fetchCount(FetchDescriptor<FieldValue>()) == 0)
	}

	// MARK: - Mutations

	@Test("touch bumps updatedAt")
	func touchBumpsUpdatedAt() {
		let item = StudyItem(taskName: "Item")
		item.updatedAt = .distantPast

		StudyItemDebugVM().touch(item)

		#expect(abs(item.updatedAt.timeIntervalSinceNow) < 1)
	}

	@Test("setStatus changes the status and bumps updatedAt", arguments: StudyItemStatus.allCases)
	func setStatusUpdatesItem(status: StudyItemStatus) {
		let item = StudyItem(taskName: "Item")
		item.updatedAt = .distantPast

		StudyItemDebugVM().setStatus(status, on: item)

		#expect(item.status == status)
		#expect(item.updatedAt > .distantPast)
	}

	@Test("setSubject links the subject and snapshots its name")
	func setSubjectSnapshotsName() {
		let item = StudyItem(taskName: "Item")
		let subject = Subject(name: "Maths", code: "MTH2")

		StudyItemDebugVM().setSubject(subject, on: item)

		#expect(item.subject?.id == subject.id)
		#expect(item.subjectName == "Maths")
	}

	@Test("setSubject(nil) clears both the link and the snapshot")
	func setSubjectNilClears() {
		let item = StudyItem(taskName: "Item", subject: Subject(name: "Maths", code: "MTH2"))

		StudyItemDebugVM().setSubject(nil, on: item)

		#expect(item.subject == nil)
		#expect(item.subjectName == nil)
	}

	// MARK: - Field values

	@Test("addValue seeds the definition's default content and links both sides")
	func addValueSeedsDefaultContent() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = StudyItemDebugVM()
		let definition = FieldDefinition(name: "Difficulty", kind: .dropdown(options: ["Easy", "Hard"]), order: 0)
		context.insert(definition)
		let item = vm.addItem(context: context)
		item.updatedAt = .distantPast

		vm.addValue(for: definition, to: item, context: context)

		let value = try #require(item.values.first)
		#expect(item.values.count == 1)
		#expect(value.content.dropdownValue == "Easy")
		#expect(value.definition?.name == "Difficulty")
		#expect(definition.values.count == 1)
		#expect(item.updatedAt > .distantPast)
	}

	@Test("delete(value:) removes the value and bumps the item")
	func deleteValueTouchesItem() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = StudyItemDebugVM()
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 0)
		context.insert(definition)
		let item = vm.addItem(context: context)
		vm.addValue(for: definition, to: item, context: context)
		let value = try #require(item.values.first)
		item.updatedAt = .distantPast

		vm.delete(value, from: item, context: context)

		#expect(item.values.isEmpty)
		#expect(try context.fetchCount(FetchDescriptor<FieldValue>()) == 0)
		#expect(item.updatedAt > .distantPast)
	}
}
