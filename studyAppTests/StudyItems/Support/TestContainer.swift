import SwiftData
@testable import studyApp

@MainActor
enum TestContainer {
	// ModelContext doesn't retain its container, and ARC may release a test's local container after its last use
	private static var retained: [ModelContainer] = []

	static func makeContainer() throws -> ModelContainer {
		let container = try ModelContainer(
			for: Schema(AppSchema.models),
			configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
		)
		container.mainContext.autosaveEnabled = false
		retained.append(container)
		return container
	}

	static func make() throws -> ModelContext {
		try makeContainer().mainContext
	}
}
