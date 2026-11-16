//  FocusLabScreen.swift
//  studyApp
//
//  DEV ONLY — the contract every Focus Design Lab design conforms to. FocusLabScaffold
//  owns the structure FocusSessionScreen has (pager, pinned timer, header band, timer
//  gap); a design only supplies what goes in each place.

import SwiftUI

struct FocusLabSlots: Equatable {
    var headerHeight: CGFloat
    var timerHeight: CGFloat
}

struct FocusLabContext {
    let session: FocusLabSession

    /// 0 on the tracking page, 1 on the focus page; already snapped under Reduce Motion.
    let blend: CGFloat

    let metrics: FocusLabStageMetrics

    /// Where the pinned timer sits, in page (safe-area) coordinates.
    let timerRect: CGRect

    var timerBackdropRect: CGRect {
        timerRect.offsetBy(dx: metrics.insets.leading, dy: metrics.insets.top)
    }
}

// DynamicProperty so a design can keep @ScaledMetric and @Environment properties of its
// own: SwiftUI installs them because the scaffold stores the design.
protocol FocusLabScreen: DynamicProperty {
    associatedtype Backdrop: View
    associatedtype TimerFace: View
    associatedtype TrackingHeader: View
    associatedtype TrackingBody: View
    associatedtype FocusHeader: View
    associatedtype FocusBody: View

    /// Full bleed, behind everything, never hit-tested.
    @ViewBuilder func backdrop(_ context: FocusLabContext) -> Backdrop

    /// Laid out in a frame the size of `timerRect`, under the pager, never hit-tested.
    @ViewBuilder func timer(_ context: FocusLabContext) -> TimerFace

    @ViewBuilder func trackingHeader(_ context: FocusLabContext) -> TrackingHeader
    @ViewBuilder func trackingBody(_ context: FocusLabContext) -> TrackingBody
    @ViewBuilder func focusHeader(_ context: FocusLabContext) -> FocusHeader
    @ViewBuilder func focusBody(_ context: FocusLabContext) -> FocusBody

    func slots(standard: FocusLabSlots) -> FocusLabSlots

    /// nil leaves the status bar and lab bar to FocusLabDesign.colorScheme.
    func chromeScheme(blend: CGFloat) -> ColorScheme?
}

extension FocusLabScreen {
    func slots(standard: FocusLabSlots) -> FocusLabSlots { standard }

    func chromeScheme(blend: CGFloat) -> ColorScheme? { nil }
}
