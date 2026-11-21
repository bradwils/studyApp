import SwiftUI

/// The shared frame every focus page sits in: header band, timer gap, then page content.
///
/// FocusPagerScaffold wraps every page in one, with the same `slots` it places the pinned timer
/// by, so pages cannot drift out of alignment with the timer drawn by the shell.
struct FocusPageScaffold<Header: View, Content: View>: View {
	let slots: FocusPagerSlots
	let horizontalPadding: CGFloat
	let header: Header
	let content: Content

	init(
		slots: FocusPagerSlots,
		horizontalPadding: CGFloat = 16,
		@ViewBuilder header: () -> Header,
		@ViewBuilder content: () -> Content
	) {
		self.slots = slots
		self.horizontalPadding = horizontalPadding
		self.header = header()
		self.content = content()
	}

	var body: some View {
		// Spacing 0 above the slot: the slot must sit exactly headerHeight down to
		// meet the pinned timer layer. Content below keeps natural spacing in its own stack.
		VStack(spacing: 0) {
			header
				.frame(height: slots.headerHeight)

			Color.clear
				.frame(height: slots.timerHeight)

			content
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.padding(.horizontal, horizontalPadding)
	}
}
