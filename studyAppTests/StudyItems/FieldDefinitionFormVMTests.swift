import Testing
import SwiftData
import Foundation
@testable import studyApp

@MainActor
@Suite("FieldDefinitionFormVM")
struct FieldDefinitionFormVMTests {

	// MARK: - canSave

	@Test("Blank names can't be saved", arguments: ["", " ", "   ", "\t"])
	func blankNameCannotSave(name: String) {
		let vm = FieldDefinitionFormVM()
		vm.name = name

		#expect(!vm.canSave)
	}

	@Test("A named text field can be saved")
	func namedTextCanSave() {
		let vm = FieldDefinitionFormVM()
		vm.name = "Pages"

		#expect(vm.canSave)
	}

	@Test("A dropdown needs at least one real option", arguments: ["", "   ", ",", " , ,"])
	func dropdownWithoutOptionsCannotSave(optionsText: String) {
		let vm = FieldDefinitionFormVM()
		vm.name = "Difficulty"
		vm.choice = .dropdown
		vm.optionsText = optionsText

		#expect(!vm.canSave)
	}

	@Test("A dropdown with options can be saved")
	func dropdownWithOptionsCanSave() {
		let vm = FieldDefinitionFormVM()
		vm.name = "Difficulty"
		vm.choice = .dropdown
		vm.optionsText = "Easy, Hard"

		#expect(vm.canSave)
	}

	@Test("Options text is irrelevant to non-dropdown kinds")
	func optionsIgnoredForOtherKinds() {
		let vm = FieldDefinitionFormVM()
		vm.name = "Pages"
		vm.choice = .number
		vm.optionsText = ""

		#expect(vm.canSave)
	}

	// MARK: - Creating

	@Test("Save inserts a trimmed, ordered definition", arguments: FieldKindChoice.allCases)
	func saveCreatesDefinition(choice: FieldKindChoice) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = FieldDefinitionFormVM()
		vm.name = "  Field  "
		vm.choice = choice
		vm.optionsText = "A, B"
		vm.isEnabled = false

		vm.save(nextOrder: 4, context: context)

		let stored = try #require(try context.fetch(FetchDescriptor<FieldDefinition>()).first)
		#expect(stored.name == "Field")
		#expect(stored.order == 4)
		#expect(stored.isEnabled == false)
		#expect(FieldKindChoice(stored.kind) == choice)
	}

	@Test("Dropdown options are split on commas, trimmed, and empties dropped")
	func dropdownOptionsAreParsed() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = FieldDefinitionFormVM()
		vm.name = "Difficulty"
		vm.choice = .dropdown
		vm.optionsText = " Easy ,, Medium,Hard , "

		vm.save(nextOrder: 0, context: context)

		let stored = try #require(try context.fetch(FetchDescriptor<FieldDefinition>()).first)
		#expect(stored.kind.dropdownOptions == ["Easy", "Medium", "Hard"])
	}

	@Test("Save does nothing when the form is invalid")
	func saveIgnoredWhenInvalid() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let vm = FieldDefinitionFormVM()
		vm.name = "   "

		vm.save(nextOrder: 0, context: context)

		#expect(try context.fetchCount(FetchDescriptor<FieldDefinition>()) == 0)
	}

	// MARK: - Editing

	@Test("load fills the form from a definition and enters edit mode")
	func loadPopulatesForm() {
		let vm = FieldDefinitionFormVM()
		let definition = FieldDefinition(name: "Difficulty", kind: .dropdown(options: ["Easy", "Hard"]), order: 1, isEnabled: false)

		vm.load(definition)

		#expect(vm.isEditing)
		#expect(vm.name == "Difficulty")
		#expect(vm.choice == .dropdown)
		#expect(vm.optionsText == "Easy, Hard")
		#expect(vm.isEnabled == false)
	}

	@Test("A fresh form is not in edit mode")
	func freshFormIsNotEditing() {
		#expect(!FieldDefinitionFormVM().isEditing)
	}

	@Test("Saving while editing updates the definition instead of inserting")
	func saveWhileEditingUpdates() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 3)
		context.insert(definition)
		let vm = FieldDefinitionFormVM()
		vm.load(definition)
		vm.name = "  Page count "
		vm.isEnabled = false

		vm.save(nextOrder: 99, context: context)

		#expect(try context.fetchCount(FetchDescriptor<FieldDefinition>()) == 1)
		#expect(definition.name == "Page count")
		#expect(definition.isEnabled == false)
		#expect(definition.order == 3)
	}

	@Test("Editing a dropdown can change its options")
	func editingDropdownUpdatesOptions() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definition = FieldDefinition(name: "Difficulty", kind: .dropdown(options: ["Easy"]), order: 0)
		context.insert(definition)
		let vm = FieldDefinitionFormVM()
		vm.load(definition)
		vm.optionsText = "Easy, Hard"

		vm.save(nextOrder: 0, context: context)

		#expect(definition.kind.dropdownOptions == ["Easy", "Hard"])
	}

	@Test("Editing a non-dropdown can't change its kind", arguments: [FieldKindChoice.number, .date, .time, .dropdown])
	func kindIsLockedForNonDropdowns(newChoice: FieldKindChoice) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definition = FieldDefinition(name: "Notes", kind: .text, order: 0)
		context.insert(definition)
		let vm = FieldDefinitionFormVM()
		vm.load(definition)
		vm.choice = newChoice
		vm.optionsText = "A, B"

		vm.save(nextOrder: 0, context: context)

		// The `.dropdown` case is a known gap: save() only guards on `choice == .dropdown`, so a text
		// field can be turned into a dropdown here and orphan its existing .text values. The debug
		// UI hides this by disabling the picker while editing; the VM itself doesn't enforce it.
		if newChoice == .dropdown {
			withKnownIssue("FieldDefinitionFormVM.save lets a non-dropdown definition become a dropdown") {
				#expect(FieldKindChoice(definition.kind) == .text)
			}
		} else {
			#expect(FieldKindChoice(definition.kind) == .text)
		}
	}

	// MARK: - Deleting

	@Test("delete removes the definition and its values")
	func deleteCascades() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definition = FieldDefinition(name: "Pages", kind: .number, order: 0)
		let value = FieldValue(content: .number(1))
		context.insert(definition)
		context.insert(value)
		value.definition = definition

		FieldDefinitionFormVM().delete(definition, context: context)

		#expect(try context.fetchCount(FetchDescriptor<FieldDefinition>()) == 0)
		#expect(try context.fetchCount(FetchDescriptor<FieldValue>()) == 0)
	}

	// MARK: - Reordering
	// Offsets follow SwiftUI's onMove convention: `destination` is the slot *before which* items land.

	@Test("move renumbers every definition to match the new order")
	func moveFirstToEnd() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C"], in: context)

		FieldDefinitionFormVM().move(definitions, from: IndexSet(integer: 0), to: 3, context: context)

		#expect(namesByOrder(definitions) == ["B", "C", "A"])
	}

	@Test("move last to first")
	func moveLastToFirst() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C"], in: context)

		FieldDefinitionFormVM().move(definitions, from: IndexSet(integer: 2), to: 0, context: context)

		#expect(namesByOrder(definitions) == ["C", "A", "B"])
	}

	@Test("move forward by one slot swaps neighbours")
	func moveForwardOne() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C"], in: context)

		FieldDefinitionFormVM().move(definitions, from: IndexSet(integer: 0), to: 2, context: context)

		#expect(namesByOrder(definitions) == ["B", "A", "C"])
	}

	@Test("Dropping an item onto its own slot is a no-op", arguments: [1, 2])
	func moveOntoSelfIsNoOp(destination: Int) throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C"], in: context)

		FieldDefinitionFormVM().move(definitions, from: IndexSet(integer: 1), to: destination, context: context)

		#expect(namesByOrder(definitions) == ["A", "B", "C"])
	}

	@Test("move handles several rows at once")
	func moveMultiple() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C", "D"], in: context)

		FieldDefinitionFormVM().move(definitions, from: IndexSet([0, 2]), to: 3, context: context)

		#expect(namesByOrder(definitions) == ["B", "A", "C", "D"])
	}

	@Test("move repairs orders that started out non-contiguous")
	func moveNormalisesOrders() throws {
		let container = try makeStudyItemContainer()
		let context = container.mainContext
		let definitions = try insertDefinitions(["A", "B", "C"], in: context)
		definitions[0].order = 10
		definitions[1].order = 20
		definitions[2].order = 30

		FieldDefinitionFormVM().move(definitions, from: IndexSet(integer: 2), to: 0, context: context)

		#expect(definitions.map(\.order).sorted() == [0, 1, 2])
	}

	// MARK: - Helpers

	private func insertDefinitions(_ names: [String], in context: ModelContext) throws -> [FieldDefinition] {
		let definitions = names.enumerated().map { FieldDefinition(name: $1, kind: .text, order: $0) }
		for definition in definitions { context.insert(definition) }
		try context.save()
		return definitions
	}

	private func namesByOrder(_ definitions: [FieldDefinition]) -> [String] {
		definitions.sorted { $0.order < $1.order }.map(\.name)
	}
}
