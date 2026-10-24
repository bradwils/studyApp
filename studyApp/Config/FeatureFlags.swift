//  FeatureFlags.swift
//  studyApp

import Foundation
import Observation

@Observable
final class FeatureFlags {
	let ring: ReleaseRing
	private(set) var overrides: [FeatureFlag: Bool]
	private let defaults: UserDefaults

	init(ring: ReleaseRing = .current, defaults: UserDefaults = .standard) {
		self.ring = ring
		self.defaults = defaults
		var stored: [FeatureFlag: Bool] = [:]
		if ring != .production {
			for flag in FeatureFlag.allCases {
				stored[flag] = defaults.object(forKey: FeatureFlags.overrideKey(for: flag)) as? Bool
			}
		}
		overrides = stored
	}

	// Production ignores stored overrides because an App Store install over a TestFlight build
	// keeps the same UserDefaults.
	var allowsOverrides: Bool { ring != .production }

	func isEnabledByDefault(_ flag: FeatureFlag) -> Bool {
		ring <= flag.enabledThrough
	}

	func isEnabled(_ flag: FeatureFlag) -> Bool {
		guard allowsOverrides, let value = overrides[flag] else { return isEnabledByDefault(flag) }
		return value
	}

	func setOverride(_ value: Bool?, for flag: FeatureFlag) {
		guard allowsOverrides else { return }
		let key = Self.overrideKey(for: flag)
		if let value {
			defaults.set(value, forKey: key)
		} else {
			defaults.removeObject(forKey: key)
		}
		overrides[flag] = value
	}

	func clearAllOverrides() {
		for flag in FeatureFlag.allCases {
			setOverride(nil, for: flag)
		}
	}

	private static func overrideKey(for flag: FeatureFlag) -> String {
		"featureFlagOverride.\(flag.rawValue)"
	}
}
