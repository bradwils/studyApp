import Foundation
import Testing
import SwiftData
@testable import studyApp

private let oldEditDate = Date(timeIntervalSinceReferenceDate: 100)
private let oldCompletionDate = Date(timeIntervalSinceReferenceDate: 200)
private let unfinishedStatuses: [StudyItemStatus] = [.notStarted, .inProgress, .onHold]

@Suite("StudyItem editing")
@MainActor
struct StudyItemEditingTests {

	@Test("Completing an item records completion and updates its edit date", arguments: unfinishedStatuses)
	func completingItemUpdatesTimestamps(status: StudyItemStatus) throws {
		let item = StudyItem(taskName: "Essay", status: status)
		item.createdAt = oldEditDate
		item.updatedAt = oldEditDate

		StudyItemDebugVM().setStatus(.completed, on: item)

		let completedAt = try #require(item.completedAt)
		#expect(item.status == .completed)
		#expect(completedAt > oldCompletionDate)
		#expect(item.updatedAt > oldEditDate)
		#expect(item.createdAt == oldEditDate)
	}

	@Test("Selecting the current status preserves timestamps", arguments: [StudyItemStatus.notStarted, .inProgress, .completed, .onHold])
	func sameStatusDoesNotEditItem(status: StudyItemStatus) {
		let item = StudyItem(taskName: "Essay", status: status)
		item.updatedAt = oldEditDate
		item.completedAt = status == .completed ? oldCompletionDate : nil
		let completedAt = item.completedAt

		StudyItemDebugVM().setStatus(status, on: item)

		#expect(item.status == status)
		#expect(item.updatedAt == oldEditDate)
		#expect(item.completedAt == completedAt)
	}

	@Test("Reopening clears completion and completing again replaces the old date", arguments: unfinishedStatuses)
	func reopeningAndCompletingAgain(status: StudyItemStatus) throws {
		let item = StudyItem(taskName: "Essay", status: .completed)
		item.completedAt = oldCompletionDate
		item.updatedAt = oldEditDate
		let vm = StudyItemDebugVM()

		vm.setStatus(status, on: item)

		#expect(item.status == status)
		#expect(item.completedAt == nil)
		#expect(item.updatedAt > oldEditDate)

		// Reset the marker so re-completion must touch the item without waiting for the clock.
		item.updatedAt = oldEditDate
		vm.setStatus(.completed, on: item)

		let completedAt = try #require(item.completedAt)
		#expect(item.status == .completed)
		#expect(completedAt > oldCompletionDate)
		#expect(item.updatedAt > oldEditDate)
	}

	@Test("Reassigning and clearing a subject refreshes its copied name and edit date")
	func subjectChangesUpdateCopiedName() throws {
		let context = try TestContainer.make()
		let original = Fixtures.subject("Maths", in: context)
		let replacement = Fixtures.subject("Physics", in: context)
		let item = Fixtures.item(in: context, subject: original)
		item.updatedAt = oldEditDate
		let vm = StudyItemDebugVM()

		vm.setSubject(replacement, on: item)

		#expect(item.subject === replacement)
		#expect(item.subjectName == "Physics")
		#expect(item.updatedAt > oldEditDate)

		item.updatedAt = oldEditDate
		vm.setSubject(nil, on: item)

		#expect(item.subject == nil)
		#expect(item.subjectName == nil)
		#expect(item.updatedAt > oldEditDate)
	}

	@Test(
		"Editing field content updates its item",
		arguments: [
			FieldContent.text("Revised outline"),
			.number(42.5),
			.date(Date(timeIntervalSinceReferenceDate: 800_000_000)),
			.time(5400),
			.dropdown("Final")
		]
	)
	func contentChangesUpdateItem(content: FieldContent) throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		let value = Fixtures.value(item: item, in: context)
		item.updatedAt = oldEditDate

		StudyItemDebugVM().setContent(content, on: value)

		let matches = switch (value.content, content) {
		case let (.text(actual), .text(expected)): actual == expected
		case let (.number(actual), .number(expected)): actual == expected
		case let (.date(actual), .date(expected)): actual == expected
		case let (.time(actual), .time(expected)): actual == expected
		case let (.dropdown(actual), .dropdown(expected)): actual == expected
		default: false
		}
		#expect(matches)
		#expect(value.item === item)
		#expect(item.updatedAt > oldEditDate)
	}

	@Test("Attaching a field saves its default and a duplicate preserves the edited value")
	func attachingFieldSavesAndRejectsDuplicates() throws {
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		let item = Fixtures.item(in: context)
		let definition = Fixtures.definition("Pages", type: .number, in: context)
		item.updatedAt = oldEditDate
		try context.save()
		let vm = StudyItemDebugVM()

		vm.addValue(for: definition, to: item, context: context)

		let reader = ModelContext(container)
		let stored = try #require(try reader.fetch(FetchDescriptor<FieldValue>()).first)
		#expect(try reader.count(FieldValue.self) == 1)
		#expect(stored.item?.id == item.id)
		#expect(stored.definition?.persistentModelID == definition.persistentModelID)
		#expect(stored.item?.values.modelIDs == [stored.persistentModelID])
		#expect(stored.definition?.values.modelIDs == [stored.persistentModelID])
		if case .number(let number) = stored.content {
			#expect(number == 0)
		} else {
			Issue.record("Attached number field did not receive its default content")
		}
		let storedItem = try #require(stored.item)
		#expect(storedItem.updatedAt > oldEditDate)
		#expect(!context.hasChanges)

		let value = try #require(item.values.first)
		let valueID = value.persistentModelID
		vm.setContent(.number(17), on: value)
		item.updatedAt = oldEditDate
		try context.save()

		vm.addValue(for: definition, to: item, context: context)

		#expect(!context.hasChanges)
		let duplicateReader = ModelContext(container)
		let retained = try #require(try duplicateReader.fetch(FetchDescriptor<FieldValue>()).first)
		#expect(try duplicateReader.count(FieldValue.self) == 1)
		#expect(retained.persistentModelID == valueID)
		#expect(retained.item?.values.modelIDs == [valueID])
		#expect(retained.definition?.values.modelIDs == [valueID])
		if case .number(let number) = retained.content {
			#expect(number == 17)
		} else {
			Issue.record("Duplicate attachment replaced the edited content")
		}
		#expect(retained.item?.updatedAt == oldEditDate)
	}
}
