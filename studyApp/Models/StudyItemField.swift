//  StudyItemField.swift
//  studyApp
//
//  A configured field on a StudyItem. `type` carries both the field's kind and its value.

import Foundation
import SwiftData

@Model
final class StudyItemField {
	var type: StudyItem.FieldKind
	
	var subject: Subject
	
	var dropdownOptions: [String]? = []//

	init(type: StudyItem.FieldKind, subject: Subject) {
        self.type = type
		self.subject = subject
		self.dropdownOptions = subject.dropdownOptions
    }
}
