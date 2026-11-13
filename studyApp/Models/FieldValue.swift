import Foundation
import SwiftData



/// A user-entered value for one custom field on a study item.
///
/// ## Declaration
///
/// ```swift
/// @Model final class FieldValue
/// ```
///
/// Each value joins one ``StudyItem`` to one ``FieldDefinition`` and carries the data
/// as a ``FieldContent`` case. ``StudyItem/values`` and ``FieldDefinition/values``
/// own it, so deleting either parent deletes the value.
///
/// ```swift
/// let value = FieldValue(content: definition.kind.config.defaultContent)
/// value.definition = definition
/// value.item = item
/// ```
///
/// > Note: Nothing enforces that `content` matches the definition's type.
@Model
final class FieldValue {
    /// The entered data. The case should match the ``definition``'s ``FieldType``.
    var content: FieldContent
    /// The item this value belongs to, or `nil` if it is detached.
    @Relationship(deleteRule: .nullify)
    var item: StudyItem?
    /// The field this value is for, or `nil` if it is detached.
    @Relationship(deleteRule: .nullify)
    var definition: FieldDefinition?
    /// Tags attached to this value alone. The inverse is ``Tag/fieldValues``,
    /// declared on the tag side; deleting the value detaches the tags and keeps them.
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []

    init(content: FieldContent) {
        self.content = content
    }
}
