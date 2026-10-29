//
//  StudyItem.swift
//  studyApp
//
//  Created by brad wils on 23/8/26.
//
import Foundation
import SwiftData

/// A unit of study work tied to a subject, with user-configurable fields.
///
/// ## Declaration
///
/// ```swift
/// @Model final class StudyItem
/// ```
///
/// Extra details live in an owned list of ``StudyItemField`` values rather than fixed properties.
///
/// ```swift
/// let item = StudyItem(subject: maths, taskName: "Past paper 2023")
/// item.fields.append(StudyItemField(type: .text("Source", "2023 exam")))
/// context.insert(item)
/// ```
///
/// > Important: Deleting an item cascades to its ``fields``; deleting its subject
/// > only nils ``subject``, so the item survives. `updatedAt` is not touched
/// > automatically, and no status property exists yet to drive ``completedAt``.
@Model
final class StudyItem {
	@Attribute(.unique) var id: UUID

	var createdAt: Date
	/// When the item was last modified. Not updated automatically.
	var updatedAt: Date
	/// When the item was completed, or `nil` while it is still open.
	var completedAt: Date?
	/// The subject this item belongs to, or `nil` once that subject is deleted.
	///
	/// `Subject` has no inverse relationship to study items, so a subject cannot list its items.
	var subject: Subject?

	var taskName: String

	//  status: StudyItemStatus     // global: .notStarted, .inProgress, .completed, .paused
	var notes: String?

	/// The custom fields the user has added to this item.
	@Relationship(deleteRule: .cascade)
	var fields: [StudyItemField]
	
//#if DEBUG {
//	var field1: FieldKind = .label("label1")
//	var defaultFields: [StudyItemField] = [
//}


	
	
	
	/// A placeholder item with dummy values, for previews and testing only.
	///
	/// Its `completedAt` is set one hour in the future, so it is not a faithful "open" item.
	init() {
		self.id = UUID()
		self.createdAt = Date.now
		self.updatedAt = Date.now
		self.completedAt = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)
		self.subject = nil
		self.taskName = "taskName"
		self.notes = "notesnotesnotes"
		
		self.fields = [StudyItemField(type: .text("labelLabel", "content"))]
	}
	
	
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        subject: Subject,
        taskName: String,
        notes: String? = nil,
        fields: [StudyItemField] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.subject = subject 
        self.taskName = taskName
        self.notes = notes
        self.fields = fields
    }
}



	
