import SwiftUI
import SwiftData

// The timer is a sibling of the pager, never a child of a page. Drawing it inside the
// scrolling content would move it with the pages no matter how carefully the two pages
// were matched; keeping it outside makes drift structurally impossible. The backgrounds
// sit outside for the same reason — a background per page drags a hard vertical seam
// across the screen on every drag.
struct FocusSessionScreen: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm: StudyTrackingViewModel

    @State private var isFocusLocked = false

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
				ticking { date in
                    backgroundLayer(at: date)
                }
				pinnedTimerLayer
            }
            pager
        }
        .toolbar(isFocusLocked ? .hidden : .visible, for: .tabBar)
        .onChange(of: vm.activeSession?.id) {
            isFocusLocked = false
        }
        .alert("Couldn't Save", isPresented: isShowingSaveError) {
            Button("OK") { vm.dismissSaveError() }
        } message: {
            Text(vm.saveErrorMessage ?? "")
        }
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { vm.saveErrorMessage != nil },
            set: { if !$0 { vm.dismissSaveError() } }
        )
    }
	/// Ticks only while the focus gradient can actually move: a running session with a target.
	/// Paused or target-less progress cannot change, so there is nothing to redraw.
    @ViewBuilder
    private func ticking<Content: View>(@ViewBuilder _ content: @escaping (Date) -> Content) -> some View {
		if vm.phase == .running && vm.hasFocusTarget {
			TimelineView(.periodic(from: .now, by: 0.5)) { context in
				content(context.date)
			}
		} else {
			content(.now)
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

				if vm.hasActiveSession {
					FocusPageContent(vm: vm, isLocked: isFocusLocked) { isFocusLocked = $0 }
						.containerRelativeFrame(.horizontal)
				}
            }
			.scrollTargetLayout()
        }
		
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.never)
		.scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(isFocusLocked)
		
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

    private func backgroundLayer(at date: Date) -> some View {
        ZStack {
            trackingGradient
                .opacity(1 - pageBlend)

            TimerGradientBackground(progress: vm.focusProgress(at: date), isTimerActive: vm.phase == .running)
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
			if vm.hasActiveSession { pageIndicator }
		}
        .allowsHitTesting(false)
    }

	private var timerDigits: some View {
		SessionTimerText(display: vm.timerDisplay)
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
                let isActive = page == FocusPagerLayout.trackingPage ? 1 - pageBlend : pageBlend
                Circle()
                    .fill(.white)
                    .opacity(0.35 + 0.65 * isActive)
                    .frame(width: 6, height: 6)
            }
        }
    }

}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = StudyTrackingViewModel()
    vm.startSession(context: container.mainContext)
    vm.startFocusTarget(duration: 5 * 60)

    return FocusSessionScreen(vm: vm)
        .modelContainer(container)
}
