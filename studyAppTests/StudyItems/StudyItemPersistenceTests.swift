import Foundation
import Testing
import SwiftData
@testable import studyApp

private let fixedDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

private func sameContent(_ lhs: FieldContent, _ rhs: FieldContent) -> Bool {
	switch (lhs, rhs) {
	case let (.text(left), .text(right)): left == right
	case let (.number(left), .number(right)): left == right
	case let (.date(left), .date(right)): abs(left.timeIntervalSince(right)) < 0.001
	case let (.time(left), .time(right)): left == right
	case let (.dropdown(left), .dropdown(right)): left == right
	default: false
	}
}

@Suite("StudyItem persistence")
@MainActor
struct StudyItemPersistenceTests {

	@Test("M1 item with every optional field round-trips")
	func itemRoundTrips() throws {
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		let subject = Fixtures.subject("Maths", in: context)
		let item = StudyItem(
			taskName: "Essay",
			subject: subject,
			notes: "Draft intro",
			status: .inProgress,
			dueDate: fixedDate,
			priority: .high
		)
		context.insert(item)
		try context.save()

		let fresh = ModelContext(container)
		let stored = try fresh.fetch(FetchDescriptor<StudyItem>())
		#expect(stored.count == 1)

		let fetched = try #require(stored.first)
		let dueDate = try #require(fetched.dueDate)
		#expect(fetched.id == item.id)
		#expect(fetched.taskName == "Essay")
		#expect(fetched.notes == "Draft intro")
		#expect(fetched.status == .inProgress)
		#expect(abs(dueDate.timeIntervalSince(fixedDate)) < 0.001)
		#expect(fetched.priority == .high)
		#expect(fetched.subject?.name == "Maths")
		#expect(fetched.subjectName == "Maths")
		#expect(fetched.completedAt == nil)
	}

	@Test(
		"M2 FieldValue content survives a fresh context",
		arguments: [
			FieldContent.text("hello"),
			.number(42.5),
			.date(fixedDate),
			.time(3600),
			.dropdown("Second")
		]
	)
	func contentRoundTrips(content: FieldContent) throws {
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		_ = Fixtures.value(content, in: context)
		try context.save()

		let fresh = ModelContext(container)
		let stored = try fresh.fetch(FetchDescriptor<FieldValue>())
		#expect(stored.count == 1)

		let fetched = try #require(stored.first)
		#expect(sameContent(fetched.content, content), "stored \(fetched.content), expected \(content)")
	}

	@Test("M3 FieldDefinition type and options survive a fresh context", arguments: [FieldType.text, .number, .date, .time, .dropdown])
	func definitionRoundTrips(type: FieldType) throws {
		let options = type == .dropdown ? ["Low", "Mid", "High"] : []
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		_ = Fixtures.definition("Field", type: type, options: options, order: 3, in: context)
		try context.save()

		let fresh = ModelContext(container)
		let stored = try fresh.fetch(FetchDescriptor<FieldDefinition>())
		#expect(stored.count == 1)

		let fetched = try #require(stored.first)
		#expect(fetched.name == "Field")
		#expect(fetched.type == type)
		#expect(fetched.options == options)
		#expect(fetched.order == 3)
		#expect(fetched.kind.type == type)
		if case .dropdown(let config) = fetched.kind {
			#expect(config.options == options)
		} else {
			#expect(type != .dropdown, "dropdown definition rebuilt as another kind")
		}
	}

	@Test("M4 realistic graph persists with the right counts")
	func graphPersists() throws {
		let container = try TestContainer.makeContainer()
		let context = container.mainContext
		let definitions = [
			Fixtures.definition("Pages", type: .number, order: 0, in: context),
			Fixtures.definition("Outline", type: .text, order: 1, in: context),
			Fixtures.definition("Stage", type: .dropdown, options: ["Draft", "Final"], order: 2, in: context)
		]
		let tags = [Fixtures.tag("urgent", in: context), Fixtures.tag("exam", in: context)]
		for name in ["Essay", "Lab report"] {
			let item = Fixtures.item(name, in: context)
			item.tags = tags
			for definition in definitions {
				_ = Fixtures.value(definition.kind.config.defaultContent, item: item, definition: definition, in: context)
			}
		}
		try context.save()

		let fresh = ModelContext(container)
		#expect(try fresh.count(StudyItem.self) == 2)
		#expect(try fresh.count(FieldDefinition.self) == 3)
		#expect(try fresh.count(FieldValue.self) == 6)
		#expect(try fresh.count(Tag.self) == 2)

		for item in try fresh.fetch(FetchDescriptor<StudyItem>()) {
			#expect(item.values.count == 3)
			#expect(item.tags.count == 2)
		}
		for definition in try fresh.fetch(FetchDescriptor<FieldDefinition>()) {
			#expect(definition.values.count == 2)
		}
		for tag in try fresh.fetch(FetchDescriptor<studyApp.Tag>()) {
			#expect(tag.items.count == 2)
		}
	}

	@Test("M5 duplicate tag name keeps the oldest tag")
	func duplicateTagKeepsOldest() throws {
		let context = try TestContainer.make()
		let vm = TagDebugVM()

		let first = try #require(vm.resolveTag(named: "Maths", color: .red, context: context))
		let second = try #require(vm.resolveTag(named: "  maths ", color: .blue, context: context))

		#expect(first.persistentModelID == second.persistentModelID)
		#expect(try context.count(Tag.self) == 1)
		#expect(second.color == .red)

		#expect(vm.resolveTag(named: "", color: .green, context: context) == nil)
		#expect(vm.resolveTag(named: " \n\t ", color: .green, context: context) == nil)
		#expect(try context.count(Tag.self) == 1)
	}

	@Test("M6 definitions fetch back sorted by order")
	func definitionsFetchSortedByOrder() throws {
		let context = try TestContainer.make()
		for order in [2, 0, 1] {
			_ = Fixtures.definition("Field \(order)", order: order, in: context)
		}
		try context.save()

		let descriptor = FetchDescriptor<FieldDefinition>(sortBy: [SortDescriptor(\FieldDefinition.order)])
		let fetched = try context.fetch(descriptor)

		#expect(fetched.map(\.order) == [0, 1, 2])
	}

	@Test("M6 item values sort by definition order in Swift")
	func itemValuesSortByDefinitionOrder() throws {
		let context = try TestContainer.make()
		let item = Fixtures.item(in: context)
		for order in [2, 0, 1] {
			let definition = Fixtures.definition("Field \(order)", order: order, in: context)
			_ = Fixtures.value(item: item, definition: definition, in: context)
		}
		try context.save()

		// item.values is unordered, so the display order comes from the definitions
		let sorted = item.values.sorted { ($0.definition?.order ?? 0) < ($1.definition?.order ?? 0) }

		#expect(sorted.map { $0.definition?.order } == [0, 1, 2])
	}
}
