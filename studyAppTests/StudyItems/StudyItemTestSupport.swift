import Foundation
import SwiftData
@testable import studyApp

// Mirrors the schema in StudyAppApp so every relationship target exists.
// SwiftData fails to build a container if a related model is missing from the list.
@MainActor
func makeStudyItemContainer() throws -> ModelContainer {
	try ModelContainer(
		for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
		RemoteUser.self, StudyItem.self, FieldDefinition.self, FieldValue.self, Tag.self,
		configurations: ModelConfiguration(isStoredInMemoryOnly: true)
	)
}

// FieldKind/FieldContent aren't Equatable, so tests read their payloads through these.
extension FieldContent {
	var textValue: String? { if case .text(let value) = self { value } else { nil } }
	var numberValue: Double? { if case .number(let value) = self { value } else { nil } }
	var dateValue: Date? { if case .date(let value) = self { value } else { nil } }
	var timeValue: TimeInterval? { if case .time(let value) = self { value } else { nil } }
	var dropdownValue: String? { if case .dropdown(let value) = self { value } else { nil } }
}

extension FieldKind {
	var dropdownOptions: [String]? { if case .dropdown(let options) = self { options } else { nil } }
}
