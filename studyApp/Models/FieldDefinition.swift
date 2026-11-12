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
    var type: FieldType
    var options: [String] = []
    // SwiftData to-many arrays are unordered
    var order: Int
    var isEnabled: Bool = true
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
