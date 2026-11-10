import SwiftData
import Testing
@testable import studyApp

@MainActor
struct StudyItemsV2FieldDefinitionFormTests {
    @Test("Invalid names and empty dropdown options cannot be saved")
    func rejectsInvalidForms() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let vm = FieldDefinitionFormVM()
        vm.name = "   "
        #expect(!vm.canSave)
        vm.save(context: writer)
        vm.name = "Difficulty"
        vm.kind = .dropdown
        vm.optionsText = " ,  , "
        #expect(!vm.canSave)
        vm.save(context: writer)

        let reader = makeStudyItemTestContext(container)
        #expect(try reader.fetchCount(FetchDescriptor<FieldDefinition>()) == 0)
    }

    @Test("Creating dropdowns trims names and filters blank options")
    func createsDropdown() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let vm = FieldDefinitionFormVM()
        vm.name = "  Difficulty  "
        vm.kind = .dropdown
        vm.optionsText = " Easy, , Medium , Hard, "
        vm.isEnabled = false
        #expect(vm.canSave)
        #expect(!vm.isEditing)
        vm.save(context: writer)

        let reader = makeStudyItemTestContext(container)
        let definition = try #require(reader.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(definition.name == "Difficulty")
        #expect(definition.kind == .dropdown)
        #expect(definition.options == ["Easy", "Medium", "Hard"])
        #expect(!definition.isEnabled)
    }

    @Test("Creating non-dropdown definitions ignores unused dropdown options")
    func nonDropdownHasNoOptions() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let vm = FieldDefinitionFormVM()
        vm.name = "Score"
        vm.kind = .number
        vm.optionsText = "One, Two"
        vm.save(context: writer)

        let reader = makeStudyItemTestContext(container)
        let definition = try #require(reader.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(definition.kind == .number)
        #expect(definition.options.isEmpty)
    }

    @Test("Editing keeps the original kind despite form state changes", arguments: FieldKind.allCases)
    func locksKindWhileEditing(kind: FieldKind) throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let definition = FieldDefinition(name: "Original", kind: kind, options: kind == .dropdown ? ["Old"] : [])
        writer.insert(definition)
        try writer.save()
        let vm = FieldDefinitionFormVM()
        vm.load(definition)
        #expect(vm.isEditing)
        #expect(vm.name == "Original")
        #expect(vm.kind == kind)
        #expect(vm.isEnabled)
        #expect(vm.optionsText == (kind == .dropdown ? "Old" : ""))
        vm.name = "  Renamed  "
        vm.isEnabled = false
        vm.kind = kind == .dropdown ? .number : .dropdown
        vm.optionsText = " First, , Second "
        vm.save(context: writer)

        let reader = makeStudyItemTestContext(container)
        let definitions = try reader.fetch(FetchDescriptor<FieldDefinition>())
        let stored = try #require(definitions.first)
        #expect(definitions.count == 1)
        #expect(stored.name == "Renamed")
        #expect(stored.kind == kind)
        #expect(!stored.isEnabled)
        #expect(stored.options == (kind == .dropdown ? ["First", "Second"] : []))
    }
}
