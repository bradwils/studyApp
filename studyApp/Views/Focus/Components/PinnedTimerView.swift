import SwiftUI

/// The session timer drawn above the pager at a fixed position.
///
/// ## Declaration
///
/// ```swift
/// struct PinnedTimerView: View
/// ```
///
/// Hit testing is off, so drags starting over the digits still reach the pager.
struct PinnedTimerView: View {
	let display: TimerDisplay

	@ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = FocusPagerLayout.timerFontBaseSize

	var body: some View {
		// This layer is the authoritative position of the timer: the slot top sits exactly
		// headerSlotHeight below the content top, and each page's scaffold has to land
		// there. Hit testing is off because otherwise a drag starting over the timer never
		// reaches the pager, and the screen refuses to swipe from the middle.
		VStack(spacing: 0) {
			Color.clear
				.frame(height: FocusPagerLayout.headerSlotHeight)

			PinnedTimerSlot()
				.overlay { timerDigits }

			Spacer()
		}
		.allowsHitTesting(false)
	}

	private var timerDigits: some View {
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
	PinnedTimerView(display: .elapsed(since: .now.addingTimeInterval(-754)))
		.background(TimerGradientBackground(progress: 0.3, isTimerActive: false).ignoresSafeArea())
}
