//  StudyItemField.swift
//  studyApp
//
//  A configured field on a StudyItem. `type` carries both the field's kind and its value.

import Foundation
import SwiftData

@Model
final class StudyItemField {
	var type: StudyItem.FieldKind //based on the enum, this will ALSO hold the value required.
	
	
	
	
	//MARK: Optionals based on seelected field Type
	//All:
	var intValue: Int? // Used for --> Slider
	var doubleValue: Double? // Used for Number
	var stringValue: String? // Used for --> Label, Dropdown
	var dateValue: Date?
	var timeIntervalValue: TimeInterval?
	
	var intMaxValue: Int? //Used for --> Max Slider Value
	var intStepValue: Int? //Used for --> intStepValue

	var selectedStrings: [String?] // Used for --> Selecetd Tags (whose potential options are derived from a @Query within the View.
	
	
	
	init(type: StudyItem.FieldKind) {
        self.type = type
    }
}
