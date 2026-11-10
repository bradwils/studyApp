import Foundation
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct StudyItemsV2TagTests {
    @Test("Tag initialization normalizes names", arguments: ["Maths", " MATHS ", "\nMaThS\t"])
    func normalizesNames(name: String) {
        #expect(Tag(name: name).key == "maths")
    }

    @Test("Tag colors survive persistence", arguments: TagColor.allCases)
    func colorRoundTrip(color: TagColor) throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        writer.insert(Tag(name: "Revision", color: color))
        try writer.save()

        let reader = makeStudyItemTestContext(container)
        let tag = try #require(reader.fetch(FetchDescriptor<Tag>()).first)
        #expect(tag.key == "revision")
        #expect(tag.color == color)
        let data = try JSONEncoder().encode(color)
        #expect(try JSONDecoder().decode(TagColor.self, from: data) == color)
    }

    @Test("Tag form rejects blank and normalized duplicate names")
    func validatesTagNames() {
        let vm = TagDebugVM()
        let existing = [Tag(name: "Maths")]
        vm.newName = " \n\t "
        #expect(!vm.canAdd(existing: existing))
        vm.newName = " \nMATHS\t "
        #expect(!vm.canAdd(existing: existing))
        vm.newName = "Physics"
        #expect(vm.canAdd(existing: existing))
    }

    @Test("Adding and deleting tags persist without caller-managed saves")
    func tagCRUD() throws {
        let container = try makeStudyItemTestContainer()
        let writer = makeStudyItemTestContext(container)
        let vm = TagDebugVM()
        vm.newName = " \nRevision\t "
        vm.newColor = .hazel
        vm.addTag(existing: [], context: writer)
        #expect(vm.newName.isEmpty)

        let reader = makeStudyItemTestContext(container)
        let tags = try reader.fetch(FetchDescriptor<Tag>())
        #expect(tags.count == 1)
        #expect(tags.first?.key == "revision")
        #expect(tags.first?.color == .hazel)

        vm.newName = "REVISION"
        vm.addTag(existing: tags, context: writer)
        let duplicateReader = makeStudyItemTestContext(container)
        #expect(try duplicateReader.fetchCount(FetchDescriptor<Tag>()) == 1)

        let tag = try #require(writer.fetch(FetchDescriptor<Tag>()).first)
        vm.delete(tag, context: writer)
        let deletedReader = makeStudyItemTestContext(container)
        #expect(try deletedReader.fetchCount(FetchDescriptor<Tag>()) == 0)
    }
}
