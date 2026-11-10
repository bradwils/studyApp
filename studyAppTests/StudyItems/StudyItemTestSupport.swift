import SwiftData
@testable import studyApp

@MainActor
func makeStudyItemTestContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self,
        SessionLocation.self, RemoteUser.self, StudyItem.self, FieldDefinition.self,
        FieldValue.self, studyApp.Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@MainActor
func makeStudyItemTestContext(_ container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
}
