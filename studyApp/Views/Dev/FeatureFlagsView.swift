//  FeatureFlagsView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Forces individual feature
//  flags on or off on this device; overrides are ignored in production builds.

import SwiftUI

struct FeatureFlagsView: View {
	@Environment(FeatureFlags.self) private var featureFlags

	var body: some View {
		List {
			Section {
				ForEach(FeatureFlag.allCases) { flag in
					flagRow(flag)
				}
			} header: {
				Text("Ring: \(featureFlags.ring.title)")
			} footer: {
				Text("Overrides are stored on this device and take effect immediately.")
			}
		}
		.navigationTitle("Feature Flags")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Reset All") {
					featureFlags.clearAllOverrides()
				}
				.disabled(featureFlags.overrides.isEmpty)
			}
		}
	}

	private func flagRow(_ flag: FeatureFlag) -> some View {
		HStack(alignment: .firstTextBaseline) {
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 6) {
					Text(flag.title)
					if featureFlags.overrides[flag] != nil {
						Circle()
							.fill(.orange)
							.frame(width: 8, height: 8)
							.accessibilityLabel("Overridden")
					}
				}
				Text(flag.summary)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			Spacer()
			Picker(flag.title, selection: overrideBinding(for: flag)) {
				Text(featureFlags.isEnabledByDefault(flag) ? "Default (On)" : "Default (Off)").tag(Bool?.none)
				Text("On").tag(Bool?.some(true))
				Text("Off").tag(Bool?.some(false))
			}
			.pickerStyle(.menu)
			.labelsHidden()
		}
	}

	private func overrideBinding(for flag: FeatureFlag) -> Binding<Bool?> {
		Binding(
			get: { featureFlags.overrides[flag] },
			set: { featureFlags.setOverride($0, for: flag) }
		)
	}
}

#Preview {
	NavigationStack {
		FeatureFlagsView()
	}
	.environment(FeatureFlags(ring: .dev, defaults: UserDefaults(suiteName: "preview")!))
}
