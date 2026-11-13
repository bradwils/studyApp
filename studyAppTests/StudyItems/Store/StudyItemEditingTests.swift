import Foundation
import SwiftData
import Testing
@testable import studyApp

@Suite("StudyItem editing regressions")
@MainActor
struct StudyItemEditingTests {
    @Test("Completing, reopening and completing again maintain the completion date")
    func completionDateFollowsStatusTransitions() throws {
        let item = StudyItem(taskName: "Essay")
        let vm = StudyItemDebugVM()
        vm.setStatus(.completed, on: item)
        #expect(item.completedAt != nil)

        let originalCompletion = Date(timeIntervalSinceReferenceDate: 100)
        item.completedAt = originalCompletion
        vm.setStatus(.completed, on: item)
        #expect(item.completedAt == originalCompletion)

        vm.setStatus(.inProgress, on: item)
        #expect(item.completedAt == nil)
        vm.setStatus(.completed, on: item)
        let latestCompletion = try #require(item.completedAt)
        #expect(latestCompletion > originalCompletion)
    }

    @Test("Editing any custom content updates the parent timestamp", arguments: [
        FieldContent.text("Edited"), .number(12), .date(Date(timeIntervalSinceReferenceDate: 100)),
        .time(600), .dropdown("Final")
    ])
    func editingContentTouchesParent(content: FieldContent) throws {
        let container = try TestContainer.makeContainer()
        let context = container.mainContext
        let item = Fixtures.item(in: context)
        let value = Fixtures.value(item: item, in: context)
        let oldDate = Date(timeIntervalSinceReferenceDate: 100)
        item.updatedAt = oldDate

        StudyItemDebugVM().setContent(content, on: value)
        try context.save()

        let reader = ModelContext(container)
        let stored = try #require(try reader.fetch(FetchDescriptor<StudyItem>()).first)
        #expect(stored.updatedAt > oldDate)
    }

    @Test("Adding the same definition twice keeps the original value")
    func addingDefinitionTwiceKeepsValue() throws {
        let context = try TestContainer.make()
        let item = Fixtures.item(in: context)
        let definition = Fixtures.definition(in: context)
        let vm = StudyItemDebugVM()
        vm.addValue(for: definition, to: item, context: context)
        let first = try #require(item.values.first)
        vm.setContent(.text("Keep me"), on: first)

        vm.addValue(for: definition, to: item, context: context)

        #expect(try context.count(FieldValue.self) == 1)
        #expect(item.values.modelIDs == [first.persistentModelID])
        if case .text(let text) = first.content {
            #expect(text == "Keep me")
        } else {
            Issue.record("Adding the definition replaced the existing content")
        }
    }

    @Test("Dropdown options trim and deduplicate without changing their order")
    func dropdownOptionsAreUniqueAndKindStaysLocked() throws {
        let context = try TestContainer.make()
        let vm = FieldDefinitionFormVM()
        vm.name = " Stage "
        vm.choice = .dropdown
        vm.optionsText = " Easy, Easy, \nHard\n, , Hard "
        vm.save(nextOrder: 0, context: context)

        let definition = try #require(try context.fetch(FetchDescriptor<FieldDefinition>()).first)
        #expect(definition.options == ["Easy", "Hard"])
        vm.load(definition)
        vm.choice = .text
        vm.optionsText = " \n "
        #expect(!vm.canSave)
        vm.optionsText = "Final, Final, Draft"
        vm.save(nextOrder: 0, context: context)

        #expect(definition.type == .dropdown)
        #expect(definition.options == ["Final", "Draft"])
    }
}
