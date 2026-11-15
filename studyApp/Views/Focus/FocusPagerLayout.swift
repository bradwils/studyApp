import SwiftUI

// Shared geometry contract between FocusSessionScreen's pinned timer layer and the
// pager pages. The timer is drawn outside the pager so it cannot move; every page
// (via FocusPageScaffold) must therefore leave an identically-sized gap at an identical
// offset, or the timer will appear to sit in a different place on each page.
enum FocusPagerLayout {

    // Fixed-height band above the timer. Tracking fills it with the subject picker and
    // today's total; Focus fills it with the subject code. Fixed rather than intrinsic
    // because a two-line header on one page and a one-line header on the other would
    // otherwise push the gap to different offsets.
    static let headerSlotHeight: CGFloat = 96

    // Base sizes for the timer digits and the slot reserved for them. Both feed a
    // @ScaledMetric(relativeTo: .largeTitle), so the 90/120 relationship is kept at every
    // Dynamic Type size.
    static let timerFontBaseSize: CGFloat = 90
    static let timerSlotBaseHeight: CGFloat = 120

    static let ringDiameter: CGFloat = 250
    static let ringLineWidth: CGFloat = 8
}

/// The gap both pages leave where the pinned timer is drawn. Sized off the same
/// @ScaledMetric base as the timer text so the gap tracks Dynamic Type with it.
struct PinnedTimerSlot: View {
    @ScaledMetric(relativeTo: .largeTitle) private var slotHeight: CGFloat = FocusPagerLayout.timerSlotBaseHeight

    var body: some View {
        Color.clear
            .frame(height: slotHeight)
    }
}
