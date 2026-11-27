import Foundation
import SwiftData

/// The places every install starts with, seeded once into ``PlaceOption``.
enum BuiltInPlace: String, CaseIterable {
    case home, library, cafe, campus, work, transit

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .cafe: "Café"
        case .campus: "Campus"
        case .work: "Work"
        case .transit: "Transit"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .library: "books.vertical"
        case .cafe: "cup.and.saucer"
        case .campus: "building.columns"
        case .work: "briefcase"
        case .transit: "tram"
        }
    }
}

/// A place the user can study at: a built-in from ``BuiltInPlace`` or one they added.
///
/// Sessions copy ``name`` into `SessionLocation.locationLabel`, so renaming or deleting
/// an option leaves past sessions unchanged.
@Model
final class PlaceOption {
    @Attribute(.unique) var id: UUID
    var name: String
    var systemImage: String
    /// The ``BuiltInPlace`` raw value; `nil` for a custom place.
    var builtInKey: String?
    var showsInPicker: Bool
    var sortOrder: Int
    var createdAt: Date
    var lastUsedAt: Date?

    var isBuiltIn: Bool { builtInKey != nil }

    init(
        id: UUID = UUID(),
        name: String,
        systemImage: String = "mappin.and.ellipse",
        builtInKey: String? = nil,
        showsInPicker: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.builtInKey = builtInKey
        self.showsInPicker = showsInPicker
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
