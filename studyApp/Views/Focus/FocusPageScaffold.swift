import SwiftUI

struct FocusPageScaffold<Header: View, Content: View>: View {
	let horizontalPadding: CGFloat
	let header: Header
	let content: Content

	init(
		horizontalPadding: CGFloat = 16,
		@ViewBuilder header: () -> Header,
		@ViewBuilder content: () -> Content
	) {
		self.horizontalPadding = horizontalPadding
		self.header = header()
		self.content = content()
	}

	var body: some View {
		// Spacing 0 above the slot: the slot must sit exactly headerSlotHeight down to
		// meet the pinned timer layer. Content below keeps natural spacing in its own stack.
		VStack(spacing: 0) {
			header
				.frame(height: FocusPagerLayout.headerSlotHeight)

			PinnedTimerSlot()

			content
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.padding(.horizontal, horizontalPadding)
	}
}
