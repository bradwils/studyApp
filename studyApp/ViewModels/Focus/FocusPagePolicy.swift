import CoreGraphics

enum FocusBackgroundStyle {
    case tracking
    case focus
}

enum FocusPagePolicy {
    static let fallbackPage: FocusPage = .tracking

    static func availablePages(for phase: SessionPhase) -> [FocusPage] {
        switch phase {
        case .idle: [.tracking]
        case .running, .paused: [.tracking, .focus]
        }
    }

    static func backgroundStyle(for page: FocusPage) -> FocusBackgroundStyle {
        switch page {
        case .tracking: .tracking
        case .focus: .focus
        }
    }
}

enum FocusPagerMath {
    static func rawPosition(contentOffset: CGFloat, leadingInset: CGFloat, viewportWidth: CGFloat) -> CGFloat? {
        guard viewportWidth > 0, viewportWidth.isFinite, contentOffset.isFinite, leadingInset.isFinite else {
            return nil
        }
        // contentOffset is measured from the inset edge, so it starts at -leading.
        return (contentOffset + leadingInset) / viewportWidth
    }

    static func clampedPosition(_ raw: CGFloat, pageCount: Int) -> CGFloat {
        guard pageCount > 1, raw.isFinite else { return 0 }
        return min(max(raw, 0), CGFloat(pageCount - 1))
    }

    static func weights(position: CGFloat, pageCount: Int) -> [Double] {
        guard pageCount > 0 else { return [] }
        let clamped = clampedPosition(position, pageCount: pageCount)
        return (0..<pageCount).map { max(0, 1 - Double(abs(clamped - CGFloat($0)))) }
    }

    static func nearestIndex(position: CGFloat, pageCount: Int) -> Int {
        guard pageCount > 0 else { return 0 }
        return Int(clampedPosition(position, pageCount: pageCount).rounded())
    }
}
