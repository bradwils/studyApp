//
//  StudyItem.swift
//  studyApp
//
//  Created by brad wils on 23/8/26.
//
import Foundation
import SwiftData

///The idea of a StudyItem has three parts:
///- Task(Name, Subject, Completed at)
///- Task Breakdown (notes
///- Configuration

@Model
final class StudyItem {
	@Attribute(.unique) var id: UUID
	
	var createdAt: Date             // set at init
	var updatedAt: Date             // touches on any mutation
	var completedAt: Date? = nil         // set when status → Completed
	var subject: Subject? = nil           // reference (nullify on subject delete)
	
	//Default fields that are user-configurable
	var taskName: String            // task name
	
	//  status: StudyItemStatus     // global: .notStarted, .inProgress, .completed, .paused
	var notes: String? = nil              // user notes
	
	@Relationship(deleteRule: .cascade)
	var fields: [StudyItemField]    // array of fields that the user can add (by default includes a couple)
	
//#if DEBUG {
//	var field1: FieldKind = .label("label1")
//	var defaultFields: [StudyItemField] = [
//}


	
	
	
	//Default, placeholder
	init() { //empty initialiser for testing
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



	
