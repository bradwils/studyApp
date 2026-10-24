//
//  FeatureFlagsTests.swift
//  studyApp
//
import Foundation
import Testing
@testable import studyApp

@MainActor
struct FeatureFlagsTests {

	private func freshDefaults() -> UserDefaults {
		UserDefaults(suiteName: UUID().uuidString)!
	}

	private func overrideKey(for flag: FeatureFlag) -> String {
		"featureFlagOverride.\(flag.rawValue)"
	}

	@Test("CI lanes map to release rings; unknown lanes fail closed to production", arguments: zip(
		[nil, "dev", "UAT-testflight", "master", "v1.2.3", "v2", "feat/foo", "hotfix/x", "vision"] as [String?],
		[ReleaseRing.local, .dev, .uat, .production, .production, .production, .production, .production, .production]
	))
	func laneMapsToRing(lane: String?, expected: ReleaseRing) {
		#expect(ReleaseRing(lane: lane) == expected)
	}

	@Test("Rings are ordered narrowest to widest audience")
	func ringsAreOrdered() {
		#expect(ReleaseRing.local < .dev)
		#expect(ReleaseRing.dev < .uat)
		#expect(ReleaseRing.uat < .production)
		#expect(ReleaseRing.allCases == ReleaseRing.allCases.sorted())
	}

	@Test("Without overrides a flag is on exactly in the rings up to enabledThrough", arguments: ReleaseRing.allCases, FeatureFlag.allCases)
	func defaultResolution(ring: ReleaseRing, flag: FeatureFlag) {
		let flags = FeatureFlags(ring: ring, defaults: freshDefaults())
		#expect(flags.isEnabled(flag) == (ring <= flag.enabledThrough))
		#expect(flags.isEnabled(flag) == flags.isEnabledByDefault(flag))
	}

	@Test("An override wins over the default outside production")
	func overrideWinsInDev() {
		let flags = FeatureFlags(ring: .dev, defaults: freshDefaults())
		let flag = FeatureFlag.devTools
		let flipped = !flags.isEnabledByDefault(flag)

		flags.setOverride(flipped, for: flag)

		#expect(flags.allowsOverrides)
		#expect(flags.overrides[flag] == flipped)
		#expect(flags.isEnabled(flag) == flipped)
	}

	@Test("Production ignores an override already stored in defaults")
	func productionIgnoresStoredOverride() {
		let defaults = freshDefaults()
		let flag = FeatureFlag.devTools
		let flipped = !FeatureFlags(ring: .production, defaults: defaults).isEnabledByDefault(flag)
		defaults.set(flipped, forKey: overrideKey(for: flag))

		let flags = FeatureFlags(ring: .production, defaults: defaults)

		#expect(!flags.allowsOverrides)
		#expect(flags.overrides.isEmpty)
		#expect(flags.isEnabled(flag) == flags.isEnabledByDefault(flag))
	}

	@Test("setOverride does nothing in production")
	func setOverrideNoOpsInProduction() {
		let defaults = freshDefaults()
		let flags = FeatureFlags(ring: .production, defaults: defaults)
		let flag = FeatureFlag.devTools

		flags.setOverride(!flags.isEnabledByDefault(flag), for: flag)

		#expect(flags.overrides.isEmpty)
		#expect(defaults.object(forKey: overrideKey(for: flag)) == nil)
		#expect(flags.isEnabled(flag) == flags.isEnabledByDefault(flag))
	}

	@Test("An override persists to a new FeatureFlags on the same defaults")
	func overridePersists() {
		let defaults = freshDefaults()
		let flag = FeatureFlag.devTools
		let first = FeatureFlags(ring: .dev, defaults: defaults)
		let flipped = !first.isEnabledByDefault(flag)

		first.setOverride(flipped, for: flag)
		let second = FeatureFlags(ring: .dev, defaults: defaults)

		#expect(second.overrides[flag] == flipped)
		#expect(second.isEnabled(flag) == flipped)
	}

	@Test("setOverride(nil) clears the override in memory and in defaults")
	func nilOverrideClears() {
		let defaults = freshDefaults()
		let flag = FeatureFlag.devTools
		let flags = FeatureFlags(ring: .dev, defaults: defaults)
		flags.setOverride(!flags.isEnabledByDefault(flag), for: flag)

		flags.setOverride(nil, for: flag)

		#expect(flags.overrides[flag] == nil)
		#expect(flags.isEnabled(flag) == flags.isEnabledByDefault(flag))
		#expect(defaults.object(forKey: overrideKey(for: flag)) == nil)
		#expect(FeatureFlags(ring: .dev, defaults: defaults).overrides.isEmpty)
	}

	@Test("clearAllOverrides removes every override")
	func clearAllOverridesClearsAll() {
		let defaults = freshDefaults()
		let flags = FeatureFlags(ring: .dev, defaults: defaults)
		for flag in FeatureFlag.allCases {
			flags.setOverride(!flags.isEnabledByDefault(flag), for: flag)
		}

		flags.clearAllOverrides()

		#expect(flags.overrides.isEmpty)
		#expect(FeatureFlags(ring: .dev, defaults: defaults).overrides.isEmpty)
	}
}
