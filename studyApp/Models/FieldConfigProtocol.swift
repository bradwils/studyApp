//
//  FieldConfigProtocol.swift
//  studyApp
//
//  Created by brad wils on 11/11/26.
//

/// Shared defaults and validation for a study item's custom field configuration.
///
/// ## Declaration
///
/// ```swift
/// protocol FieldConfig: Codable
/// ```
/// Concrete configurations supply an SF Symbol name and initial field content.
/// Validation defaults to `true`; configurations with constraints override it.
protocol FieldConfig: Codable {
	var systemImage: String { get }
	var defaultContent: FieldContent { get }
	/// Whether the configuration meets its constraints; callers must check this explicitly.
	var isValid: Bool { get }
}
