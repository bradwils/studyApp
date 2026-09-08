import SwiftUI
import SwiftData

// The timer is a sibling of the pager, never a child of a page. Drawing it inside the
// scrolling content would move it with the pages no matter how carefully the two pages
// were matched; keeping it outside makes drift structurally impossible. The backgrounds
// sit outside for the same reason — a background per page drags a hard vertical seam
// across the screen on every drag.
struct FocusSessionScreen: View {
	
	@State private var scrollPage: Int = 1
 
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm: StudyTrackingViewModel

    /// 0 on the tracking page, 1 on the focus page, provides continious scale for opacity functions
    @State private var pageOffset: CGFloat = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 90

    // Defaulted so every real call site (MainTabView) is unaffected; the preview below
    // injects a pre-seeded vm so the animated gradient has something to show.
    init(vm: StudyTrackingViewModel = StudyTrackingViewModel()) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            // backgroundLayer and pinnedTimerLayer share one TimelineView so timerDigits'
            // blendMode(.difference) composites against the actual gradient pixels instead
            // of being isolated into its own empty layer — confirmed in the simulator.
            // pager stays outside so a tick doesn't rebuild page content; drawing it last
            // (on top) is safe because pinnedTimerLayer already disables hit testing, and
            // both pager pages leave the same headerSlotHeight gap the digits sit in, so
            // nothing visually overlaps.
			
			///Ticking pushes our changes for the background layer
			
			ZStack {
				ticking {
                    backgroundLayer
//                    pinnedTimerLayer moved --> check this doesnt cause isues!
                }
				pinnedTimerLayer
            }
            pager
        }
    }
	/// Allow periodic updates for contained views; currently used to allow the creeping foucs session gradient background to update every 0.5s
    /// double viewbuilder allows for, if needed, stacked views to be parsed through
    @ViewBuilder
    private func ticking<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View { //remember; Content is a generic term, 'content' is what we're identifying the closure as. Here, we're ultimately saying 'something generic, Content, needs to conform to some type of View. content, my closure, is what ends up getting captured by the second closure (TimelineView(xxyz) { HERE } (and persists beyond just the function, as per @escaping).
		switch vm.currentSessionState {
		case .noSession:
			content()
		case .sessionRunning(let anchor), .sessionPaused(let anchor):
			TimelineView(.periodic(from: anchor, by: 0.5)) { _ in //analyse the battery drain & potential differences later, can probably be nuked to 10s
				content()
			}
		}
    }

    // Reduce Motion gets the destination state rather than a crossfade travelling with the drag.
    private var pageBlend: Double {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return Double(pageOffset)
    }

    // MARK: - Pager

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                TrackingPageContent(vm: vm)
                    .containerRelativeFrame(.horizontal)

				if (vm.sessionIsRunning) {
					FocusPageContent(vm: vm)
						.containerRelativeFrame(.horizontal)
				}
            }
			.scrollTargetLayout()
        }
		
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.never)
		.scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(vm.focusLockEnabled)
		
		///Track how far we've moved between screen1 and screen2. Needed to animate the gradual opacity of the bg & the pager dots
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            let width = geometry.containerSize.width
            guard width > 0 else { return 0 }
            // contentOffset is measured from the inset edge, so it starts at -leading.
            let travelled = geometry.contentOffset.x + geometry.contentInsets.leading
            return min(max(travelled / width, 0), 1)
        } action: { _, offset in
            pageOffset = offset
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            trackingGradient
                .opacity(1 - pageBlend)

            TimerGradientBackground(progress: vm.pureFocusSessionProgress ?? 0, isTimerActive: vm.timerIsRunning)
                .opacity(pageBlend)
        }
        .ignoresSafeArea()
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

    // MARK: - Pinned Timer Layer

    // This layer is the authoritative position of the timer: the slot top sits exactly
    // FocusPagerLayout.headerSlotHeight below the content top, and each page's
    // PinnedTimerSlot has to land there. Hit testing is off because otherwise a drag
    // starting over the timer never reaches the pager, and the screen refuses to swipe
    // from the middle.
    private var pinnedTimerLayer: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: FocusPagerLayout.headerSlotHeight)

            PinnedTimerSlot()
                .overlay { timerDigits }

            Spacer()
        }
		.overlay(alignment: .top) {
			if case .sessionRunning = vm.currentSessionState { pageIndicator }
		}
        .allowsHitTesting(false)
    }

	//main Timer Element Content. Runs through two enums; changing content based on first if there is a PureFocusSession active and second by the state of the second (given no PureFocusSession)
	private var timerDigits: some View {
		Group {
			if (vm.isFocusSessionRunning) {
				ElapsedTimerText(anchor: vm.activePureFocusSession!.pureFocusGoal) // change timer to pureFocus start time anchor
			} else {
				switch vm.currentSessionState {
				case .noSession:
					Text("--:--")
				case .sessionRunning(let anchor): //anchor = total study time cumulative
					ElapsedTimerText(anchor: anchor)
				case .sessionPaused(let anchor): //anchor = start of break time
					ElapsedTimerText(anchor: anchor)
				}
			}


		}
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

    // Concentric with the digits because it lives in this fixed layer, but only means
    // anything on the focus page, so it fades in with the swipe.

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { page in
                let isActive = page == FocusPagerLayout.trackingPage ? 1 - pageBlend : pageBlend //re-update this!
                Circle()
                    .fill()
                    .frame(width: 6, height: 6)
            }
        }
    }

}

#Preview {
    let container = try! ModelContainer(
        for: StudySession.self, Subject.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = StudyTrackingViewModel()
    vm.startSession(ctx: container.mainContext)
    vm.startPureFocusSession(5 * 60)

    return FocusSessionScreen(vm: vm)
        .modelContainer(container)
}
