import SwiftData

/// The set of SwiftData models the app persists.
///
/// ## Declaration
///
/// ```swift
/// enum AppSchema
/// ```
///
/// The app container and the test containers both build from ``models``, so the two
/// can't drift apart.
///
/// ```swift
/// let container = try ModelContainer(
///     for: Schema(AppSchema.models),
///     configurations: ModelConfiguration(isStoredInMemoryOnly: true)
/// )
/// ```
///
/// > Important: Add every new `@Model` type to ``models``. A model missing from the
/// > list is absent from the container and fails at runtime when first used.
enum AppSchema {
    /// The single source of truth for the persisted model types.
    static let models: [any PersistentModel.Type] = [
        Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        RemoteUser.self, StudyItem.self, FieldDefinition.self, FieldValue.self, Tag.self
    ]
}
