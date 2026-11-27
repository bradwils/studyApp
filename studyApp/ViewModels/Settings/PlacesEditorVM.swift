import Foundation
import SwiftData

@Observable
final class PlacesEditorVM {
    var newPlaceName: String = ""

    private var trimmedName: String { newPlaceName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canAddPlace: Bool { !trimmedName.isEmpty && trimmedName.count <= 32 }

    static func seedBuiltIns(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<PlaceOption>())) ?? []
        let seededKeys = Set(existing.compactMap(\.builtInKey))
        let missing = BuiltInPlace.allCases.enumerated().filter { !seededKeys.contains($0.element.rawValue) }
        guard !missing.isEmpty else { return }

        for (index, place) in missing {
            context.insert(PlaceOption(
                name: place.title,
                systemImage: place.systemImage,
                builtInKey: place.rawValue,
                sortOrder: index
            ))
        }
        try? context.save()
    }

    /// Returns `false` when the name is invalid or a place with that name already exists.
    @discardableResult
    func addPlace(context: ModelContext) -> Bool {
        guard canAddPlace else { return false }
        let name = trimmedName
        let existing = (try? context.fetch(FetchDescriptor<PlaceOption>())) ?? []
        guard !existing.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            return false
        }

        let nextOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        context.insert(PlaceOption(name: name, sortOrder: nextOrder))
        try? context.save()
        newPlaceName = ""
        return true
    }

    func setShowsInPicker(_ shows: Bool, for place: PlaceOption, context: ModelContext) {
        place.showsInPicker = shows
        try? context.save()
    }

    func removePlace(_ place: PlaceOption, context: ModelContext) {
        guard !place.isBuiltIn else { return }
        context.delete(place)
        try? context.save()
    }
}
