//
//  FieldConfigProtocol.swift
//  studyApp
//
//  Created by brad wils on 11/11/26.
//

protocol FieldConfig: Codable {
	var systemImage: String { get }
	var defaultContent: FieldContent { get }
	var isValid: Bool { get }
}
