import Testing
import CoreGraphics
@testable import studyApp

struct FocusPagerTests {

	@Test("Three-page weights follow the contract table", arguments: [
		(CGFloat(-0.3), [1.0, 0, 0]),
		(CGFloat(0.25), [0.75, 0.25, 0]),
		(CGFloat(1.5), [0, 0.5, 0.5]),
		(CGFloat(2.4), [0, 0, 1]),
	])
	func weightTable(position: CGFloat, expected: [Double]) {
		let weights = FocusPagerMath.weights(position: position, pageCount: 3)
		for (actual, wanted) in zip(weights, expected) {
			#expect(abs(actual - wanted) < 0.0001)
		}
	}

	@Test("A single page always weighs one")
	func singlePage() {
		#expect(FocusPagerMath.weights(position: 5, pageCount: 1) == [1])
		#expect(FocusPagerMath.weights(position: -2, pageCount: 1) == [1])
	}

	@Test("Overscroll clamps to the page range")
	func overscrollClamps() {
		#expect(FocusPagerMath.clampedPosition(-1, pageCount: 2) == 0)
		#expect(FocusPagerMath.clampedPosition(4, pageCount: 2) == 1)
	}

	@Test("Unusable geometry yields nil")
	func unusableGeometry() {
		#expect(FocusPagerMath.rawPosition(contentOffset: 10, leadingInset: 0, viewportWidth: 0) == nil)
		#expect(FocusPagerMath.rawPosition(contentOffset: .nan, leadingInset: 0, viewportWidth: 300) == nil)
		#expect(FocusPagerMath.rawPosition(contentOffset: 150, leadingInset: 0, viewportWidth: 300) == 0.5)
	}

	@Test("Removing the selected page falls back to tracking and resets position")
	func reconcileFallsBack() {
		let state = FocusScreenState(pages: [.tracking, .focus])
		state.navigate(to: .focus)
		state.updatePosition(raw: 1)
		state.scrollDidSettle()
		#expect(state.settledPage == .focus)

		state.reconcile(availablePages: [.tracking])
		#expect(state.scrolledPage == .tracking)
		#expect(state.settledPage == .tracking)
		#expect(state.position == 0)
	}

	@Test("A still-valid selection survives reconcile")
	func reconcileKeepsSelection() {
		let state = FocusScreenState(pages: [.tracking])
		state.reconcile(availablePages: [.tracking, .focus])
		state.navigate(to: .focus)
		state.reconcile(availablePages: [.tracking, .focus])
		#expect(state.scrolledPage == .focus)
	}

	@Test("Session identity change clears the lock")
	func lockClears() {
		let state = FocusScreenState()
		state.setLocked(true)
		state.sessionIdentityDidChange()
		#expect(!state.isLocked)
	}

	@Test("Reduce Motion projects to the nearest page")
	func reduceMotion() {
		let state = FocusScreenState(pages: [.tracking, .focus])
		state.updatePosition(raw: 0.4)
		#expect(state.weight(of: .tracking, reduceMotion: true) == 1)
		#expect(state.weight(of: .focus, reduceMotion: true) == 0)
		state.updatePosition(raw: 0.6)
		#expect(state.weight(of: .focus, reduceMotion: true) == 1)
	}
}
