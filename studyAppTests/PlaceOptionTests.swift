import Foundation
import SwiftData
import Testing
@testable import studyApp

// Autosave is off so a missing explicit save shows up when a fresh context refetches.
@MainActor
struct PlaceOptionTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchema.models)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    private func makeContext(_ container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func fetchPlaces(_ context: ModelContext) throws -> [PlaceOption] {
        try context.fetch(FetchDescriptor<PlaceOption>(sortBy: [SortDescriptor(\.sortOrder)]))
    }

    @Test("Seeding inserts every built-in once, however often it runs")
    func seedingIsIdempotent() throws {
        let container = try makeContainer()

        PlacesEditorVM.seedBuiltIns(context: makeContext(container))
        PlacesEditorVM.seedBuiltIns(context: makeContext(container))

        let places = try fetchPlaces(makeContext(container))
        #expect(places.map(\.builtInKey) == BuiltInPlace.allCases.map(\.rawValue))
        #expect(places.map(\.name) == BuiltInPlace.allCases.map(\.title))
        #expect(places.allSatisfy { $0.showsInPicker })
    }

    @Test("Seeding restores a missing built-in without duplicating the rest")
    func seedingFillsGaps() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        PlacesEditorVM.seedBuiltIns(context: context)
        let library = try #require(try fetchPlaces(context).first { $0.builtInKey == BuiltInPlace.library.rawValue })
        context.delete(library)
        try context.save()

        PlacesEditorVM.seedBuiltIns(context: makeContext(container))

        let keys = try fetchPlaces(makeContext(container)).compactMap(\.builtInKey)
        #expect(keys.count == BuiltInPlace.allCases.count)
        #expect(Set(keys) == Set(BuiltInPlace.allCases.map(\.rawValue)))
    }

    @Test("Adding a custom place saves it after the built-ins and rejects a duplicate name")
    func addingCustomPlace() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        PlacesEditorVM.seedBuiltIns(context: context)
        let vm = PlacesEditorVM()

        vm.newPlaceName = "  Gran's house "
        #expect(vm.addPlace(context: context))
        #expect(vm.newPlaceName.isEmpty)

        vm.newPlaceName = "gran's HOUSE"
        #expect(!vm.addPlace(context: context))
        vm.newPlaceName = "library"
        #expect(!vm.addPlace(context: context))

        let places = try fetchPlaces(makeContext(container))
        let custom = try #require(places.last)
        #expect(places.count == BuiltInPlace.allCases.count + 1)
        #expect(custom.name == "Gran's house")
        #expect(custom.builtInKey == nil)
        #expect(custom.showsInPicker)
    }

    @Test("Hiding a place from the picker persists, and built-ins can't be removed")
    func togglingAndRemoving() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        PlacesEditorVM.seedBuiltIns(context: context)
        let vm = PlacesEditorVM()
        let home = try #require(try fetchPlaces(context).first)

        vm.setShowsInPicker(false, for: home, context: context)
        vm.removePlace(home, context: context)

        let stored = try #require(try fetchPlaces(makeContext(container)).first)
        #expect(stored.builtInKey == BuiltInPlace.home.rawValue)
        #expect(!stored.showsInPicker)
    }

    @Test("The chosen place is saved on the session and remembered for the next one")
    func chosenPlacePersistsOnSession() throws {
        let container = try makeContainer()
        let context = makeContext(container)
        PlacesEditorVM.seedBuiltIns(context: context)
        let places = try fetchPlaces(context)
        let library = try #require(places.first { $0.builtInKey == BuiltInPlace.library.rawValue })
        let cafe = try #require(places.first { $0.builtInKey == BuiltInPlace.cafe.rawValue })
        var current = Date(timeIntervalSinceReferenceDate: 1_000)
        let vm = StudyTrackingViewModel(now: { current })

        vm.selectPlace(library, context: context)
        vm.startSession(context: context)
        current += 60
        vm.selectPlace(cafe, context: context)
        current += 60
        vm.pauseSession(context: context)
        vm.finishSession(context: context)

        let reader = makeContext(container)
        let session = try #require(try reader.fetch(FetchDescriptor<StudySession>()).first)
        #expect(session.location?.locationLabel == "Café")
        #expect(try reader.fetch(FetchDescriptor<SessionLocation>()).count == 1)
        let storedCafe = try #require(try fetchPlaces(reader).first { $0.builtInKey == BuiltInPlace.cafe.rawValue })
        #expect(storedCafe.lastUsedAt == Date(timeIntervalSinceReferenceDate: 1_060))

        let nextLaunch = StudyTrackingViewModel(now: { current })
        nextLaunch.restoreLastPlace(context: reader)
        #expect(nextLaunch.selectedPlaceName == "Café")
    }
}
