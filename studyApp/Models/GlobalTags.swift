import Foundation
import SwiftData


/// A global label that study items and field values can carry.
///
/// ## Declaration
///
/// ```swift
/// @Model final class Tag
/// ```
///
/// A tag is identified by ``key``, its trimmed, lowercased name, so "Maths" and
/// "maths" are the same tag. Tags are shared: many items and field values can
/// reference one tag.
///
/// ```swift
/// let tag = Tag(name: "  Exam ", color: .red)
/// tag.key // "exam"
/// ```
///
/// > Important: `.unique` makes SwiftData upsert on a duplicate key, overwriting the
/// > oldest tag instead of failing. Create tags through `TagDebugVM.resolveTag`,
/// > which looks up an existing key first and keeps the oldest tag.
@Model
final class Tag {
    /// The trimmed, lowercased name. Unique, so "Maths" and "maths" can't both exist.
    @Attribute(.unique) var key: String
    /// The tag's display colour; gray unless chosen otherwise.
    var color: TagColor = TagColor.gray

    /// The study items carrying this tag. Many-to-many; deleting the tag removes it
    /// from those items without deleting them.
    @Relationship(deleteRule: .nullify, inverse: \StudyItem.tags)
    var items: [StudyItem] = []

    /// The field values carrying this tag, like ``items``.
    ///
    /// This side declares the inverse for ``FieldValue/tags``; the field-value side does not.
    @Relationship(deleteRule: .nullify, inverse: \FieldValue.tags)
    var fieldValues: [FieldValue] = []


    init(name: String, color: TagColor = .gray) {
        self.key = Tag.key(for: name)
        self.color = color
    }

    static let defaultName = "default"

    /// Normalizes a display name into a tag key by trimming surrounding whitespace and lowercasing.
    ///
    /// - Parameter name: The name as typed.
    /// - Returns: The key to store and look up; empty if `name` is blank.
    static func key(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// The colours a tag can be shown in; the default is gray.
///
/// ## Declaration
///
/// ```swift
/// enum TagColor: String, Codable, CaseIterable
/// ```
enum TagColor: String, Codable, CaseIterable {
    case red, orange, green, blue, purple, mango, hazel, white, gray
}
