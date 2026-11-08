import Foundation
import SwiftData

///FieldValue is one/many fields in a StudyItem that contains user-modifiable data about
///the current StudyItem.
///
///Every storage slot exists on the model; `definition.kind` decides which one is live.
///Dropdown selections are stored in `textValue`.
@Model
final class FieldValue {
    var textValue: String?
    var numberValue: Double?
    var dateValue: Date?
    var timeValue: TimeInterval?
    @Relationship(deleteRule: .nullify)
    var item: StudyItem?
    @Relationship(deleteRule: .nullify)
    var definition: FieldDefinition?
    var tags: [Tag] = []

    init(textValue: String? = nil, numberValue: Double? = nil, dateValue: Date? = nil, timeValue: TimeInterval? = nil) {
        self.textValue = textValue
        self.numberValue = numberValue
        self.dateValue = dateValue
        self.timeValue = timeValue
    }
}
