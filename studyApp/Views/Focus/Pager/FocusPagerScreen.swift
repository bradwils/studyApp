//  FocusPagerScreen.swift
//  studyApp
//
//  The contract a focus screen conforms to. FocusPagerScaffold owns the structure
//  FocusSessionScreen has (pager, pinned timer, header band, timer gap); a screen only
//  supplies what goes in each place.

import SwiftUI

/// The heights of the two fixed bands at the top of every page.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPagerSlots: Equatable
/// ```
///
/// Both pages and the pinned timer read one value of this type, so the timer gap sits at the
/// same offset on each page.
struct FocusPagerSlots: Equatable {
    /// The band above the timer that holds each page's header.
    var headerHeight: CGFloat
    /// The gap each page leaves for the pinned timer.
    var timerHeight: CGFloat
}

/// The layout values a screen needs to draw one frame.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPagerContext
/// ```
///
/// ``FocusPagerScaffold`` builds one per layout pass and hands it to every requirement of
/// ``FocusPagerScreen``. Rects come in two coordinate spaces: page (safe-area) coordinates for
/// anything inside a page, and backdrop coordinates for anything drawn in the full-bleed backdrop.
///
/// > Important: On screens wider than `FocusPagerLayout.maxContentWidth` the column is narrower
/// > than the screen. Align backdrop content to ``contentBackdropRect``, not to `metrics.fullSize`.
struct FocusPagerContext {

    /// 0 on the tracking page, 1 on the focus page; already snapped under Reduce Motion.
    let blend: CGFloat

    /// The safe-area size and insets of the whole screen, not of the column.
    let metrics: FocusPagerStageMetrics

    /// Where the pinned timer sits, in page (safe-area) coordinates. Inside `contentRect`.
    let timerRect: CGRect

    /// The centred column every page and the timer are laid out in, in page (safe-area) coordinates.
    var contentRect: CGRect { metrics.contentRect }

    /// The column in backdrop coordinates.
    var contentBackdropRect: CGRect { metrics.backdropRect(contentRect) }

    /// The timer slot in backdrop coordinates.
    var timerBackdropRect: CGRect { metrics.backdropRect(timerRect) }
}

/// The content of a two-page study screen: a tracking page and a focus page around one pinned timer.
///
/// ## Declaration
///
/// ```swift
/// protocol FocusPagerScreen: DynamicProperty
/// ```
///
/// A conforming type supplies what goes in each place and holds its own state as a stored
/// property; ``FocusPagerScaffold`` owns the pager, the page blend and where everything sits.
/// It refines `DynamicProperty` so a screen can keep `@ScaledMetric` and `@Environment`
/// properties, which SwiftUI installs because the scaffold stores the screen.
///
/// ```swift
/// struct MyScreen: FocusPagerScreen {
///     let vm: StudyTrackingViewModel
///     var showsFocusPage: Bool { vm.sessionIsRunning }
///     var isLocked: Bool { vm.focusLockEnabled }
///     func backdrop(_ context: FocusPagerContext) -> some View { Color.black }
///     // timer, trackingHeader, trackingBody, focusHeader, focusBody
/// }
/// ```
///
/// > Note: The timer is drawn once, outside the pages, so it cannot move during a swipe.
/// > Pages never draw it; they only get the gap.
protocol FocusPagerScreen: DynamicProperty {
    associatedtype Backdrop: View
    associatedtype TimerFace: View
    associatedtype TrackingHeader: View
    associatedtype TrackingBody: View
    associatedtype FocusHeader: View
    associatedtype FocusBody: View

    /// The focus page exists only while this is true.
    var showsFocusPage: Bool { get }

    /// Swiping between the pages is disabled while this is true.
    var isLocked: Bool { get }

    /// Full bleed, behind everything, never hit-tested.
    @ViewBuilder func backdrop(_ context: FocusPagerContext) -> Backdrop

    /// Laid out in a frame the size of `timerRect`, under the pager, never hit-tested.
    @ViewBuilder func timer(_ context: FocusPagerContext) -> TimerFace

    /// Placed in the header band of the tracking page; `trackingBody` fills the space under the timer gap.
    @ViewBuilder func trackingHeader(_ context: FocusPagerContext) -> TrackingHeader
    @ViewBuilder func trackingBody(_ context: FocusPagerContext) -> TrackingBody
    @ViewBuilder func focusHeader(_ context: FocusPagerContext) -> FocusHeader
    @ViewBuilder func focusBody(_ context: FocusPagerContext) -> FocusBody

    /// Returns the band heights for this screen. The default keeps `standard`, the real screen's sizes.
    func slots(standard: FocusPagerSlots) -> FocusPagerSlots
}

extension FocusPagerScreen {
    func slots(standard: FocusPagerSlots) -> FocusPagerSlots { standard }
}
