//
//  FieldConfigProtocol.swift
//  studyApp
//
//  Created by brad wils on 11/11/26.
//

/// The behavior every custom field kind provides: an icon, a starting value, and
/// a check that its own settings make sense.
///
/// ## Declaration
///
/// ```swift
/// protocol FieldConfig: Codable
/// ```
/// Each ``FieldKind`` case wraps one config struct. Code that needs the icon or
/// default for a field reads it through ``FieldKind/config`` instead of switching
/// on the kind, so what a kind does lives in its config struct alone.
///
/// ## Writing a config
///
/// Conform a struct, supply the two required properties, and store any settings
/// the kind needs. Override ``isValid`` only if those settings have constraints.
///
/// ```swift
/// struct RatingFieldConfig: FieldConfig {
///     var maxStars: Int
///
///     var systemImage: String { "star" }
///     var defaultContent: FieldContent { .number(0) }
///     var isValid: Bool { (1...10).contains(maxStars) }
/// }
/// ```
/// `defaultContent` must return the ``FieldContent`` case that matches the kind,
/// and must not crash when the config is invalid.
///
/// ## Using a config
///
/// Read shared behavior through the kind:
///
/// ```swift
/// let icon = definition.kind.config.systemImage
/// let value = FieldValue(content: definition.kind.config.defaultContent)
/// ```
///
/// ## Validate before displaying
///
/// `isValid` is never called automatically. Check it when a config is created or
/// edited, before it is saved or shown, and keep the config out of the UI if it
/// fails. Constraints belong in `isValid`, not in the views.
///
/// ```swift
/// let config = DropdownFieldConfig(options: [])
/// guard config.isValid else { return }
/// ```
/// Because configs are plain values, they can be checked in a unit test with no
/// view or model container: assert `isValid` for good and bad settings, and that
/// `defaultContent` is the expected case.
///
/// > Important: Configs are never persisted. ``FieldDefinition`` stores `type` and
/// > plain per-kind columns such as `options`, then rebuilds the config through
/// > ``FieldKind/init(type:options:)``. A new config property needs a matching
/// > column on ``FieldDefinition`` and must be passed through that initializer.
protocol FieldConfig: Codable {
	/// SF Symbol name shown beside the field.
	var systemImage: String { get }
	/// The value a new ``FieldValue`` starts with.
	var defaultContent: FieldContent { get }
	/// Whether the configuration meets its constraints; callers must check this
	/// explicitly. Defaults to `true` for configs with no constraints.
	var isValid: Bool { get }
}


extension FieldConfig {
	var isValid: Bool { true }
}
