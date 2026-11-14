import SwiftUI

// Observe page weights here so continuous scrolling redraws only the backdrop.
struct FocusBackgroundLayer: View {
	let screenState: FocusScreenState
	let tracking: StudyTrackingViewModel

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		// Paused or target-less progress cannot change, so there is nothing to redraw.
		if tracking.phase == .running && tracking.hasFocusTarget {
			TimelineView(.periodic(from: .now, by: 0.5)) { context in
				backdrop(at: context.date)
			}
		} else {
			backdrop(at: .now)
		}
	}

	private func backdrop(at date: Date) -> some View {
		ZStack {
			trackingGradient
				.opacity(weight(of: .tracking))

			TimerGradientBackground(progress: tracking.focusProgress(at: date), isTimerActive: tracking.phase == .running)
				.opacity(weight(of: .focus))
		}
		.ignoresSafeArea()
	}

	private func weight(of style: FocusBackgroundStyle) -> Double {
		screenState.pages
			.filter { FocusPagePolicy.backgroundStyle(for: $0) == style }
			.reduce(0) { $0 + screenState.weight(of: $1, reduceMotion: reduceMotion) }
	}

	private var trackingGradient: some View {
		ZStack {
			LinearGradient(
				colors: [
					Color.pink.opacity(0.35),
					Color.purple.opacity(0.35),
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			LinearGradient(
				colors: [
					Color.white.opacity(0.35),
					Color.blue.opacity(0.35),
				],
				startPoint: .topTrailing,
				endPoint: .bottomLeading
			)
		}
	}
}
