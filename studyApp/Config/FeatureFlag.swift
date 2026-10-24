//  FeatureFlag.swift
//  studyApp

import Foundation

nonisolated enum FeatureFlag: String, CaseIterable, Identifiable {
	case devTools

	var id: String { rawValue }

	// The widest ring that sees this flag. Roll out by widening it on dev and promoting as usual;
	// delete the case once it has shipped at .production for a release.
	var enabledThrough: ReleaseRing {
		switch self {
		case .devTools: .dev
		}
	}

	var title: String {
		switch self {
		case .devTools: "Developer Tools"
		}
	}

	var summary: String {
		switch self {
		case .devTools: "Debug data inspector and fake-session generator in Settings."
		}
	}
}
