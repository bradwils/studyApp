//  ReleaseRing.swift
//  studyApp

import Foundation

// nonisolated opts this pure value type out of the target's default MainActor isolation,
// so its Comparable conformance and CaseIterable cases are usable from any context (incl. tests).
nonisolated enum ReleaseRing: Int, Comparable, CaseIterable {
	// Ordered narrowest to widest audience; FeatureFlags compares rings by this order.
	case local, dev, uat, production

	static let current = ReleaseRing(lane: Bundle.main.object(forInfoDictionaryKey: "StudyAppLane") as? String)

	init(lane: String?) {
		switch lane {
		case nil: self = .local
		case "dev"?: self = .dev
		case "UAT-testflight"?: self = .uat
		// master, release tags (v1.2.3) and any unknown lane fail closed to shipped features only
		default: self = .production
		}
	}

	static func < (lhs: ReleaseRing, rhs: ReleaseRing) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

	var title: String {
		switch self {
		case .local: "Local"
		case .dev: "Dev"
		case .uat: "UAT"
		case .production: "Production"
		}
	}
}
