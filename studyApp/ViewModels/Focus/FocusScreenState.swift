import CoreGraphics
import Observation

// Keep continuous position reads in drawing views to avoid rebuilding page content.
@Observable
final class FocusScreenState {
    // Assigning this binding requests a destination; settledPage commits when scrolling stops.
    var scrolledPage: FocusPage?
    private(set) var pages: [FocusPage]
    private(set) var settledPage: FocusPage
    private(set) var position: CGFloat
    private(set) var isLocked = false

    init(pages: [FocusPage] = [FocusPagePolicy.fallbackPage]) {
        let normalized = Self.normalized(pages)
        self.pages = normalized
        self.scrolledPage = normalized.first
        self.settledPage = normalized.first ?? FocusPagePolicy.fallbackPage
        self.position = 0
    }

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

    // Late geometry from the previous layout is clamped to the current page count.
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
