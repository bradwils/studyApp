import SwiftUI
import SwiftData

// Renders through FocusPagerScaffold with FocusSessionContent, so the real screen and every
// Focus Design Lab screen share one structure. Three layers, back to front: the background
// (FocusBackgroundLayer), the pinned timer (PinnedTimerView, with the page dots on top), and
// the pager (FocusPager) holding the pages. Each ticks or scrolls on its own: the background
// owns its 0.5 s timeline, the timer digits own theirs, and the pager redraws only for page
// changes. The timer is a sibling of the pager, never a child of a page, so drift is
// structurally impossible; the backgrounds sit outside for the same reason — a background per
// page drags a hard vertical seam across the screen on every drag.
struct FocusSessionScreen: View {

    let vm: StudyTrackingViewModel

    @State private var screenState = FocusScreenState()

    var body: some View {
        FocusPagerScaffold(screen: FocusSessionContent(vm: vm), screenState: screenState)
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
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = StudyTrackingViewModel()
    vm.startSession(context: container.mainContext)
    vm.startFocusTarget(duration: 5 * 60, context: container.mainContext)

    return FocusSessionScreen(vm: vm)
        .modelContainer(container)
}
