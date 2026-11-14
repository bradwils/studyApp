import Foundation
import CoreGraphics
import Observation

/// Scroll, position and lock state for the focus session pager.
///
/// ## Declaration
///
/// ```swift
/// @Observable final class FocusScreenState
/// ```
///
/// Separates the requested destination (`scrolledPage`), the last committed page
/// (`settledPage`) and the continuous `position`. Use `settledPage` for discrete policy and
/// `position` only for drawing.
///
/// > Important: `position` changes every scroll frame. Read it only in views that draw from it.
@Observable
final class FocusScreenState {
    /// Bound to `.scrollPosition(id:)`; assigning it requests a destination.
    var scrolledPage: FocusPage?
    private(set) var pages: [FocusPage]
    /// The page committed when scrolling last went idle.
    private(set) var settledPage: FocusPage
    /// Clamped fractional page index.
    private(set) var position: CGFloat
    private(set) var isLocked = false

    init(pages: [FocusPage] = [FocusPagePolicy.fallbackPage]) {
        let normalized = Self.normalized(pages)
        self.pages = normalized
        self.scrolledPage = normalized.first
        self.settledPage = normalized.first ?? FocusPagePolicy.fallbackPage
        self.position = 0
    }

    /// Visual weight of a page; with Reduce Motion, 1 for the nearest page and 0 otherwise.
    func weight(of page: FocusPage, reduceMotion: Bool) -> Double {
        guard let index = pages.firstIndex(of: page) else { return 0 }
        if reduceMotion {
            return index == FocusPagerMath.nearestIndex(position: position, pageCount: pages.count) ? 1 : 0
        }
        return FocusPagerMath.weights(position: position, pageCount: pages.count)[index]
    }

    func navigate(to page: FocusPage) {
        guard pages.contains(page) else { return }
        scrolledPage = page
    }

    /// Adopts a new page list, keeping the current page when it survives and falling back otherwise.
    func reconcile(availablePages: [FocusPage]) {
        let normalized = Self.normalized(availablePages)
        guard normalized != pages else { return }
        pages = normalized

        let target: FocusPage
        if let scrolledPage, normalized.contains(scrolledPage) {
            target = scrolledPage
        } else if normalized.contains(settledPage) {
            target = settledPage
        } else {
            target = FocusPagePolicy.fallbackPage
        }
        scrolledPage = target
        settledPage = target
        position = CGFloat(normalized.firstIndex(of: target) ?? 0)
    }

    /// A late callback from the old layout is harmless: it is clamped to the current page count.
    func updatePosition(raw: CGFloat?) {
        guard let raw else {
            position = CGFloat(pages.firstIndex(of: settledPage) ?? 0)
            return
        }
        position = FocusPagerMath.clampedPosition(raw, pageCount: pages.count)
    }

    func scrollDidSettle() {
        let index = FocusPagerMath.nearestIndex(position: position, pageCount: pages.count)
        guard pages.indices.contains(index) else { return }
        settledPage = pages[index]
        position = CGFloat(index)
    }

    func setLocked(_ locked: Bool) {
        isLocked = locked
    }

    func sessionIdentityDidChange() {
        isLocked = false
    }

    private static func normalized(_ pages: [FocusPage]) -> [FocusPage] {
        var seen = Set<FocusPage>()
        var result = pages.filter { seen.insert($0).inserted }
        if !result.contains(FocusPagePolicy.fallbackPage) {
            result.insert(FocusPagePolicy.fallbackPage, at: 0)
        }
        return result
    }
}
