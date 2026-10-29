import Foundation
import SwiftData

@Model
final class FieldDefinition {
    var name: String
    var kind: FieldKind
    // SwiftData to-many arrays are unordered
    var order: Int
    var isEnabled: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.definition)
    var values: [FieldValue] = []

    init(name: String, kind: FieldKind, order: Int, isEnabled: Bool = true) {
        self.name = name
        self.kind = kind
        self.order = order
        self.isEnabled = isEnabled
    }
}
