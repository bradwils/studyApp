import Foundation
import CoreGraphics

/// Which backdrop the shell draws for a page.
enum FocusBackgroundStyle {
    case tracking
    case focus
}

/// Decides which pages are available and how each one is presented.
///
/// ## Declaration
///
/// ```swift
/// enum FocusPagePolicy
/// ```
///
/// Both answers are exhaustive switches, so adding a ``FocusPage`` forces a decision here.
enum FocusPagePolicy {
    /// The page every list contains and every removal falls back to.
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

/// Pure geometry for the pager: scroll offsets in, fractional positions and weights out.
///
/// ## Declaration
///
/// ```swift
/// enum FocusPagerMath
/// ```
///
/// Indices exist only inside this type and where they are mapped back to a ``FocusPage``;
/// they are never page identity.
enum FocusPagerMath {
    /// Horizontal travel in pages, or `nil` when the geometry is unusable.
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

    /// Per-page weights on the clamped position; they sum to one.
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
