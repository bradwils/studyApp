import SwiftUI

/// The session timer digits. FocusPagerScaffold places them in the timer slot, under the
/// pager, with hit testing off so drags starting over the digits still reach the pager.
struct PinnedTimerView: View {
	let display: TimerDisplay

	@ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = FocusPagerLayout.timerFontBaseSize

	var body: some View {
		SessionTimerText(display: display)
			.font(
				.system(
					size: timerFontSize,
					weight: .semibold,
					design: .monospaced
				)
			)
			// Auto-contrast against whatever's underneath, instead of thresholding
			// focusProgress by hand: difference(white, background) flips black/white.
			.foregroundStyle(.white)
			.blendMode(.difference)
	}
}

#Preview {
	let start = Date.now.addingTimeInterval(-754)
	PinnedTimerView(display: .elapsed(timing: .started(at: start), tickOrigin: start))
		.background(TimerGradientBackground(progress: 0.3, isTimerActive: false).ignoresSafeArea())
}
