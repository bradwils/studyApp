import Foundation
import SwiftData



///FieldValue is one/many fields in a StudyItem that contains user-modifiable data about
///the current StudyItem.
///
///We need a `FieldContent`, an enum that contains the type of data + values (if needed)
@Model
final class FieldValue {
    var content: FieldContent
    @Relationship(deleteRule: .nullify)
    var item: StudyItem?
    @Relationship(deleteRule: .nullify)
    var definition: FieldDefinition?
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []

    init(content: FieldContent) {
        self.content = content
    }
}
