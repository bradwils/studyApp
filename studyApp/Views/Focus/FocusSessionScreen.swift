import SwiftUI
import SwiftData

// Three layers, back to front: the background (FocusBackgroundLayer), the pinned timer
// (PinnedTimerView, with the page dots on top), and the pager (FocusPager) holding the
// pages. Each ticks or scrolls on its own: the background owns its 0.5 s timeline, the
// timer digits own theirs, and the pager redraws only for page changes. The timer is a
// sibling of the pager, never a child of a page, so drift is structurally impossible; the
// backgrounds sit outside for the same reason — a background per page drags a hard
// vertical seam across the screen on every drag. The pager is drawn last because the
// timer layer disables hit testing, and every page leaves the same gap the digits sit in.
struct FocusSessionScreen: View {

    let vm: StudyTrackingViewModel

    @State private var screenState = FocusScreenState()

    var body: some View {
        ZStack {
            FocusBackgroundLayer(screenState: screenState, tracking: vm)

            PinnedTimerView(display: vm.timerDisplay)
                .overlay(alignment: .top) {
                    FocusPageIndicator(screenState: screenState)
                }
                .allowsHitTesting(false)

            FocusPager(screenState: screenState) { page in
                pageContent(for: page)
            }
        }
        .toolbar(screenState.isLocked ? .hidden : .visible, for: .tabBar)
        .onChange(of: FocusPagePolicy.availablePages(for: vm.phase), initial: true) { _, pages in
            var transaction = Transaction()
            if let scrolled = screenState.scrolledPage, !pages.contains(scrolled) {
                transaction.disablesAnimations = true
            }
            withTransaction(transaction) {
                screenState.reconcile(availablePages: pages)
            }
        }
        .onChange(of: vm.activeSession?.id) {
            screenState.sessionIdentityDidChange()
        }
        .alert("Couldn't Save", isPresented: isShowingSaveError) {
            Button("OK") { vm.dismissSaveError() }
        } message: {
            Text(vm.saveErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func pageContent(for page: FocusPage) -> some View {
        switch page {
        case .tracking:
            TrackingPageContent(vm: vm)
        case .focus:
            FocusPageContent(vm: vm, isLocked: screenState.isLocked) { screenState.setLocked($0) }
        }
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { vm.saveErrorMessage != nil },
            set: { if !$0 { vm.dismissSaveError() } }
        )
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
