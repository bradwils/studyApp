import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
@Suite("StudyItem model")
struct StudyItemTests {

	// MARK: - Initialiser defaults

	@Test("New item starts not-started with no optional data")
	func initDefaults() {
		let item = StudyItem(taskName: "Past paper")

		#expect(item.taskName == "Past paper")
		#expect(item.status == .notStarted)
		#expect(item.notes == nil)
		#expect(item.dueDate == nil)
		#expect(item.priority == nil)
		#expect(item.completedAt == nil)
		#expect(item.subject == nil)
		#expect(item.subjectName == nil)
		#expect(item.tag == nil)
		#expect(item.values.isEmpty)
		#expect(abs(item.createdAt.timeIntervalSinceNow) < 1)
		#expect(item.updatedAt >= item.createdAt)
	}

	@Test("Each item gets its own id")
	func idsAreUnique() {
		#expect(StudyItem(taskName: "A").id != StudyItem(taskName: "B").id)
	}

	@Test("Initialising with a subject snapshots its name")
	func initCopiesSubjectName() {
		let subject = Subject(name: "Maths", code: "MTH2")
		let item = StudyItem(taskName: "Past paper", subject: subject)

		#expect(item.subject?.id == subject.id)
		#expect(item.subjectName == "Maths")
	}

	@Test("Initialising as completed stamps completedAt")
	func initCompletedStampsCompletedAt() throws {
		let item = StudyItem(taskName: "Done already", status: .completed)

		let completedAt = try #require(item.completedAt)
		#expect(abs(completedAt.timeIntervalSinceNow) < 1)
	}

	@Test("Only the completed status stamps completedAt at init", arguments: [StudyItemStatus.notStarted, .inProgress, .onHold])
	func initNonCompletedLeavesCompletedAtNil(status: StudyItemStatus) {
		#expect(StudyItem(taskName: "Not done", status: status).completedAt == nil)
	}

	// MARK: - Persistence

	@Test("Item and all its optional fields survive a save and fetch")
	func persistsAllFields() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let due = Date(timeIntervalSince1970: 1_800_000_000)

		let item = StudyItem(taskName: "Essay", notes: "Intro first", status: .inProgress, dueDate: due, priority: .high)
		context.insert(item)
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<StudyItem>()).first)
		#expect(fetched.id == item.id)
		#expect(fetched.taskName == "Essay")
		#expect(fetched.notes == "Intro first")
		#expect(fetched.status == .inProgress)
		#expect(fetched.dueDate == due)
		#expect(fetched.priority == .high)
	}

	@Test("Every status round-trips through the store", arguments: StudyItemStatus.allCases)
	func statusRoundTrips(status: StudyItemStatus) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(StudyItem(taskName: "Item", status: status))
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<StudyItem>()).first)
		#expect(fetched.status == status)
	}

	@Test("Every priority round-trips through the store", arguments: StudyItemPriority.allCases)
	func priorityRoundTrips(priority: StudyItemPriority) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		context.insert(StudyItem(taskName: "Item", priority: priority))
		try context.save()

		let fetched = try #require(try context.fetch(FetchDescriptor<StudyItem>()).first)
		#expect(fetched.priority == priority)
	}

	// MARK: - Subject relationship

	@Test("Item appears in its subject's items (inverse is maintained)")
	func subjectInverse() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let subject = Subject(name: "Maths", code: "MTH2")
		let item = StudyItem(taskName: "Past paper", subject: subject)
		context.insert(subject)
		context.insert(item)
		try context.save()

		#expect(subject.items.map(\.id) == [item.id])
	}

	@Test("Deleting a subject keeps the item and its subjectName")
	func deletingSubjectNullifiesButKeepsItem() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let subject = Subject(name: "Maths", code: "MTH2")
		let item = StudyItem(taskName: "Past paper", subject: subject)
		context.insert(subject)
		context.insert(item)
		try context.save()

		context.delete(subject)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<StudyItem>()) == 1)
		#expect(item.subject == nil)
		#expect(item.subjectName == "Maths")
	}

	@Test("Deleting an item leaves its subject in place")
	func deletingItemKeepsSubject() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let subject = Subject(name: "Maths", code: "MTH2")
		let item = StudyItem(taskName: "Past paper", subject: subject)
		context.insert(subject)
		context.insert(item)
		try context.save()

		context.delete(item)
		try context.save()

		#expect(try context.fetchCount(FetchDescriptor<Subject>()) == 1)
		#expect(subject.items.isEmpty)
	}

	// MARK: - Open decisions

	// DebugVM.setStatus still carries `TODO(human): decide how completedAt follows status changes`.
	// These expectations are the obvious reading, not a decision — enable once that is settled
	// (and move the logic out of the debug VM, which is where the test should point).
	@Test(.disabled("Pending decision: how completedAt follows status changes (StudyItemDebugVM.setStatus TODO)"))
	func completedAtFollowsStatusChanges() throws {
		let item = StudyItem(taskName: "Item")
		let vm = StudyItemDebugVM()

		vm.setStatus(.completed, on: item)
		#expect(item.completedAt != nil)

		vm.setStatus(.inProgress, on: item)
		#expect(item.completedAt == nil)
	}
}
