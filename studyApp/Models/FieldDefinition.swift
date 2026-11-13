import Foundation
import SwiftData

/// A user-defined field that study items can hold values for.
///
/// ## Declaration
///
/// ```swift
/// @Model final class FieldDefinition
/// ```
///
/// `type` and `options` are the persisted shape. ``kind`` is derived from them
/// at runtime, so adding a per-kind setting means adding a column here and
/// passing it through ``FieldKind/init(type:options:)``.
///
/// > Note: `options` is only read by the dropdown type; other kinds ignore it.
@Model
final class FieldDefinition {
    var name: String
    /// The persisted kind of the field; use ``kind`` for its configuration.
    var type: FieldType
    /// The choices for a dropdown field; ignored by other types.
    var options: [String] = []
    /// Display position among all definitions.
    ///
    /// Stored explicitly because SwiftData to-many arrays are unordered.
    var order: Int
    /// Whether the field is enabled; disabling it does not delete its stored values.
    var isEnabled: Bool = true
    /// Every value entered for this field. Deleting the definition deletes these values.
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.definition)
    var values: [FieldValue] = []

    /// The runtime view of `type` and `options`; not persisted.
    var kind: FieldKind { FieldKind(type: type, options: options) }

    init(name: String, type: FieldType, options: [String] = [], order: Int, isEnabled: Bool = true) {
        self.name = name
        self.type = type
        self.options = options
        self.order = order
        self.isEnabled = isEnabled
    }
}
