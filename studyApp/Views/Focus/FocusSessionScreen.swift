import SwiftUI
import SwiftData

// Keep the timer outside the pager so it stays pinned, and backgrounds outside to avoid
// seams during drags. Each page reserves the same timer slot; hit testing passes through
// the timer to the pager. Independent timelines keep ticks out of the pager's observation.
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
        .onChange(of: vm.activeSessionID) {
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
