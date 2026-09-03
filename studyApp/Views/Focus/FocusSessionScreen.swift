import SwiftUI
import SwiftData

// The timer is a sibling of the pager, never a child of a page. Drawing it inside the
// scrolling content would move it with the pages no matter how carefully the two pages
// were matched; keeping it outside makes drift structurally impossible. The backgrounds
// sit outside for the same reason — a background per page drags a hard vertical seam
// across the screen on every drag.
struct FocusSessionScreen: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm = StudyTrackingViewModel()

    // 0 on the tracking page, 1 on the focus page, continuous in between.
    @State private var pageOffset: CGFloat = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 90

    var body: some View {
        ZStack {
            // focusProgress resolves Date.now on read, so @Observable has nothing to
            // invalidate on and the ring, gradient and colour would render once and
            // freeze. These two layers are pumped by a clock instead; the pager is
            // deliberately left outside so a tick doesn't rebuild the page content.
            ticking { backgroundLayer }
            pager
            ticking { pinnedTimerLayer }
        }
    }

    // Redraw pump only — the closure re-reads vm.focusProgress on each tick rather than
    // deriving anything from the tick date. Idle sessions need no pump at all.
    @ViewBuilder
    private func ticking<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        switch vm.currentSessionState {
        case .noSession:
            content()
        case .sessionRunning(let anchor), .sessionPaused(let anchor):
            TimelineView(.periodic(from: anchor, by: 1)) { _ in
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

                FocusPageContent(vm: vm)
                    .containerRelativeFrame(.horizontal)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(vm.focusLockEnabled)
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

            TimerGradientBackground(progress: vm.focusProgress, isTimerActive: vm.timerIsRunning)
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
                .overlay { progressRing }

            Spacer()
        }
        .overlay(alignment: .top) {
            pageIndicator
                .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }

    private var timerDigits: some View {
        Group {
            switch vm.currentSessionState {
            case .noSession:
                Text("--:--")
            case .sessionRunning(let anchor):
                ElapsedTimerText(anchor: anchor)
            case .sessionPaused(let anchor):
                ElapsedTimerText(anchor: anchor)
            }
        }
        .font(
            .system(
                size: timerFontSize,
                weight: .semibold,
                design: .monospaced
            )
        )
        .foregroundStyle(timerColor)
    }

    // Concentric with the digits because it lives in this fixed layer, but only means
    // anything on the focus page, so it fades in with the swipe.
    private var progressRing: some View {
        Circle()
            .trim(from: 0, to: vm.focusProgress)
            .stroke(
                timerColor.opacity(0.8),
                style: StrokeStyle(lineWidth: FocusPagerLayout.ringLineWidth, lineCap: .round)
            )
            .frame(width: FocusPagerLayout.ringDiameter, height: FocusPagerLayout.ringDiameter)
            .rotationEffect(.degrees(-90))
            .opacity(vm.targetDuration == nil ? 0 : pageBlend)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { page in
                let isActive = page == FocusPagerLayout.trackingPage ? 1 - pageBlend : pageBlend
                Circle()
                    .fill(timerColor.opacity(0.2 + 0.5 * isActive))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // The focus gradient turns white from the bottom up, so past its midpoint the digits
    // flip to black — the same rule PureFocusView applies to its own controls.
    private var timerColor: Color {
        let focusColor: Color = vm.focusProgress > 0.6 ? .black : .white
        return Color.primary.mix(with: focusColor, by: pageBlend)
    }
}

#Preview {
    FocusSessionScreen()
        .modelContainer(for: [StudySession.self, Subject.self], inMemory: true)
}
