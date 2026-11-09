import Foundation
import SwiftData

@Model
final class FieldDefinition {
    var name: String
    var kind: FieldKind
    var options: [String] = []
    var isEnabled: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.definition)
    var values: [FieldValue] = []

    init(name: String, kind: FieldKind, options: [String] = [], isEnabled: Bool = true) {
        self.name = name
        self.kind = kind
        self.options = options
        self.isEnabled = isEnabled
    }
}
