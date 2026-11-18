import SwiftData
@testable import studyApp

@MainActor
enum Fixtures {
	static func subject(_ name: String = "Maths", in context: ModelContext) -> Subject {
		let subject = Subject(name: name, code: "TST")
		context.insert(subject)
		return subject
	}

	static func item(_ name: String = "Item", in context: ModelContext, subject: Subject? = nil) -> StudyItem {
		let item = StudyItem(taskName: name, subject: subject)
		context.insert(item)
		return item
	}

	static func definition(
		_ name: String = "Field",
		type: FieldType = .text,
		options: [String] = [],
		order: Int = 0,
		in context: ModelContext
	) -> FieldDefinition {
		let definition = FieldDefinition(name: name, type: type, options: options, order: order)
		context.insert(definition)
		return definition
	}

	static func value(
		_ content: FieldContent = .text(""),
		item: StudyItem? = nil,
		definition: FieldDefinition? = nil,
		in context: ModelContext
	) -> FieldValue {
		let value = FieldValue(content: content)
		context.insert(value)
		value.item = item
		value.definition = definition
		return value
	}

	static func tag(_ name: String = "tag", color: TagColor = .gray, in context: ModelContext) -> Tag {
		let tag = Tag(name: name, color: color)
		context.insert(tag)
		return tag
	}
}

extension Sequence where Element: PersistentModel {
	@MainActor var modelIDs: [PersistentIdentifier] { map(\.persistentModelID) }
}

extension ModelContext {
	@MainActor func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
		try fetchCount(FetchDescriptor<T>())
	}
}
