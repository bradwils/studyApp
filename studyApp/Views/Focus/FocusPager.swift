import SwiftUI

/// The horizontal paging container for the focus session pages.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPager<Page: View>: View
/// ```
///
/// Renders `screenState.pages` and reports scroll geometry and settlement back to the
/// state. It never reads `position`, so scrolling does not rebuild page content.
struct FocusPager<Page: View>: View {
	let screenState: FocusScreenState
	let page: (FocusPage) -> Page

	init(screenState: FocusScreenState, @ViewBuilder page: @escaping (FocusPage) -> Page) {
		self.screenState = screenState
		self.page = page
	}

	var body: some View {
		@Bindable var screenState = screenState
		ScrollView(.horizontal) {
			HStack(spacing: 0) {
				ForEach(screenState.pages) { item in
					page(item)
						.containerRelativeFrame(.horizontal)
						.id(item)
				}
			}
			.scrollTargetLayout()
		}
		.scrollPosition(id: $screenState.scrolledPage)
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.never)
		.scrollBounceBehavior(.basedOnSize)
		.scrollDisabled(screenState.isLocked)
		.onScrollGeometryChange(for: CGFloat?.self) { geometry in
			FocusPagerMath.rawPosition(
				contentOffset: geometry.contentOffset.x,
				leadingInset: geometry.contentInsets.leading,
				viewportWidth: geometry.containerSize.width
			)
		} action: { _, raw in
			screenState.updatePosition(raw: raw)
		}
		.onScrollPhaseChange { _, new in
			if new == .idle { screenState.scrollDidSettle() }
		}
	}
}
