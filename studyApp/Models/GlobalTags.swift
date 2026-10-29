import Foundation
import SwiftData


//Tags are global items that can be assigned to a studyItem. They do not confirm to a relationship, or anything of sorts.
@Model
final class Tag {
    // Lowercased + trimmed name; unique so "Maths" and "maths" can't both exist
    @Attribute(.unique) var key: String
    var color: TagColor = TagColor.blue


    init(name: String, color: TagColor = .blue) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.key = Tag.key(for: trimmed)
        self.color = color
    }

    static let defaultName = "default"

    static func key(for name: String) -> String {
        name.lowercased()
    }
}

enum TagColor: String, Codable, CaseIterable {
    case red, orange, green, blue, purple, mango, hazel, white
}
