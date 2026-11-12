import SwiftData

/// The app container and the test containers both build from this list.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        RemoteUser.self, StudyItem.self, FieldDefinition.self, FieldValue.self, Tag.self
    ]
}
