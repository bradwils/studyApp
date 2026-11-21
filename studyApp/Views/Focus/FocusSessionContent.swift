import SwiftUI

// The real study screen's conformance: what FocusPagerScaffold draws in each place for a
// live StudyTrackingViewModel session. Each page's header and content are separate views so
// the scaffold can place them around the pinned timer.
struct FocusSessionContent: FocusPagerScreen {

    let vm: StudyTrackingViewModel

    var phase: SessionPhase { vm.phase }

    var sessionID: UUID? { vm.activeSessionID }

    func backdrop(_ context: FocusPagerContext) -> some View {
        FocusBackgroundLayer(screenState: context.screenState, tracking: vm)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        PinnedTimerView(display: vm.timerDisplay)
    }

    func overlay(_ context: FocusPagerContext) -> some View {
        FocusPageIndicator(screenState: context.screenState)
    }

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            TrackingPageHeader(vm: vm)
        case .focus:
            FocusPageHeader(vm: vm)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            TrackingPageContent(vm: vm)
        case .focus:
            FocusPageContent(vm: vm, isLocked: context.isLocked, onLockChange: context.setLocked)
        }
    }

    func horizontalPadding(for page: FocusPage) -> CGFloat {
        switch page {
        case .tracking: 16
        case .focus: 24
        }
    }
}
