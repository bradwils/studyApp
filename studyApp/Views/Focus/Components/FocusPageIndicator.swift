import SwiftUI

/// Page dots that track the pager's scroll position.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPageIndicator: View
/// ```
///
/// Renders nothing for fewer than two pages. Decorative: hidden from VoiceOver.
struct FocusPageIndicator: View {
	let screenState: FocusScreenState

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		if screenState.pages.count > 1 {
			HStack(spacing: 6) {
				ForEach(screenState.pages) { page in
					Circle()
						.fill(.white)
						.opacity(0.35 + 0.65 * screenState.weight(of: page, reduceMotion: reduceMotion))
						.frame(width: 6, height: 6)
				}
			}
			.accessibilityHidden(true)
		}
	}
}

#Preview {
	let state = FocusScreenState(pages: [.tracking, .focus])
	state.updatePosition(raw: 0.4)
	return FocusPageIndicator(screenState: state)
		.padding()
		.background(Color.purple.opacity(0.4))
}
