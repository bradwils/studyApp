//  FocusPagerScreen.swift
//  studyApp
//
//  The contract every focus screen conforms to. FocusPagerScaffold owns FocusSessionScreen's
//  structure (backdrop, pinned timer, FocusPager over FocusScreenState, header band and timer
//  gap on every page); a screen only supplies what goes in each place.

import SwiftUI

/// The shared header and timer heights for every page.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPagerSlots: Equatable
/// ```
///
/// The scaffold applies the same heights to the pages and the pinned timer.
/// The standard timer height scales with Dynamic Type.
struct FocusPagerSlots: Equatable {
    /// The band above the timer that holds each page's header.
    var headerHeight: CGFloat
    /// The gap each page leaves for the pinned timer.
    var timerHeight: CGFloat
}

/// The layout and pager values a screen needs to draw one frame.
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
/// > Important: `blend` and `weight(of:)` read `FocusScreenState.position`, which changes every
/// > scroll frame. Read them inside the view that draws from them, not in a page's parent, so a
/// > swipe redraws only that view.
///
/// > Important: On screens wider than `FocusPagerLayout.maxContentWidth` the column is narrower
/// > than the screen. Align backdrop content to ``contentBackdropRect``, not to `metrics.fullSize`.
struct FocusPagerContext {

    let screenState: FocusScreenState

    /// The safe-area size and insets of the whole screen, not of the column.
    let metrics: FocusPagerStageMetrics

    let slots: FocusPagerSlots

    let reduceMotion: Bool

    /// How much of `page` is on screen, 0...1; snapped to the nearest page under Reduce Motion.
    func weight(of page: FocusPage) -> Double {
        screenState.weight(of: page, reduceMotion: reduceMotion)
    }

    /// The focus-page weight from 0 to 1, snapped to the nearest page under Reduce Motion.
    var blend: CGFloat { CGFloat(weight(of: .focus)) }

    var isLocked: Bool { screenState.isLocked }

    func setLocked(_ locked: Bool) {
        screenState.setLocked(locked)
    }

    /// The centred column every page and the timer are laid out in, in page (safe-area) coordinates.
    var contentRect: CGRect { metrics.contentRect }

    /// Where the pinned timer sits, in page (safe-area) coordinates. Inside `contentRect`.
    var timerRect: CGRect {
        CGRect(x: contentRect.minX, y: slots.headerHeight, width: contentRect.width, height: slots.timerHeight)
    }

    /// The column in backdrop coordinates.
    var contentBackdropRect: CGRect { metrics.backdropRect(contentRect) }

    /// The timer slot in backdrop coordinates.
    var timerBackdropRect: CGRect { metrics.backdropRect(timerRect) }
}

/// Supplies the visual layers and page content around a shared timer.
///
/// ## Declaration
///
/// ```swift
/// protocol FocusPagerScreen: DynamicProperty
/// ```
///
/// A conforming type supplies what goes in each place; ``FocusPagerScaffold`` owns the pager,
/// which pages exist (``FocusPagePolicy`` from `phase`), the lock and where everything sits.
/// It refines `DynamicProperty` so a screen can keep `@ScaledMetric` and `@Environment`
/// properties, which SwiftUI installs because the scaffold stores the screen.
///
/// Use exhaustive page switches in the header and content implementations so adding
/// a page exposes the layouts that need updating.
///
/// > Note: The timer is drawn once, outside the pages, so it cannot move during a swipe.
/// > Pages never draw it; they only get the gap.
protocol FocusPagerScreen: DynamicProperty {
    associatedtype Backdrop: View
    associatedtype TimerFace: View
    associatedtype Overlay: View = EmptyView
    associatedtype Header: View
    associatedtype Content: View

    /// Decides the available pages through `FocusPagePolicy.availablePages(for:)`.
    var phase: SessionPhase { get }

    /// A change unlocks the screen, so a new session never starts locked.
    var sessionID: UUID? { get }

    /// Full bleed, behind everything, never hit-tested.
    @ViewBuilder func backdrop(_ context: FocusPagerContext) -> Backdrop

    /// Laid out in a frame the size of `timerRect`, under the pager, never hit-tested.
    @ViewBuilder func timer(_ context: FocusPagerContext) -> TimerFace

    /// Laid out over the column, top-aligned, under the pager, never hit-tested. Defaults to nothing.
    @ViewBuilder func overlay(_ context: FocusPagerContext) -> Overlay

    /// Placed in the header band of `page`; `content(for:_:)` fills the space under the timer gap.
    @ViewBuilder func header(for page: FocusPage, _ context: FocusPagerContext) -> Header
    @ViewBuilder func content(for page: FocusPage, _ context: FocusPagerContext) -> Content

    /// Inset applied to both the header and the content of `page`. Defaults to 16.
    func horizontalPadding(for page: FocusPage) -> CGFloat

    /// Overrides the shared band heights. Keep the standard timer height to inherit Dynamic Type scaling.
    func slots(standard: FocusPagerSlots) -> FocusPagerSlots
}

extension FocusPagerScreen {
    func horizontalPadding(for page: FocusPage) -> CGFloat { 16 }

    func slots(standard: FocusPagerSlots) -> FocusPagerSlots { standard }
}

extension FocusPagerScreen where Overlay == EmptyView {
    func overlay(_ context: FocusPagerContext) -> EmptyView { EmptyView() }
}
