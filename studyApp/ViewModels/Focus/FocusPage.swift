import Foundation

/// A page of the focus session pager.
///
/// ## Declaration
///
/// ```swift
/// enum FocusPage: Hashable, Identifiable
/// ```
///
/// Identity is the case itself, never an index. Which pages exist right now comes from
/// ``FocusPagePolicy``, so a known page can be unavailable in a given session.
///
/// ## Role in the pager
///
/// The enum only names a page. Availability, scroll state, layout and content are each
/// decided elsewhere and keyed by this type:
///
/// - ``FocusPagePolicy`` chooses which pages exist for a session phase and which backdrop each gets.
/// - ``FocusScreenState`` holds the live page list, the requested and settled pages, and the scroll position.
/// - ``FocusPager`` draws one view per page and tags it with `.id(page)`, so scroll position binds to the case.
/// - ``FocusSessionScreen`` maps each page to its content view and reconciles the state when the phase changes.
///
/// ```text
/// SessionPhase ─▶ FocusPagePolicy ─▶ [FocusPage] ─▶ FocusScreenState
///                                                       │ pages, scrolledPage
///                                                       ▼
/// FocusSessionScreen ─ pageContent(for:) ─▶ FocusPager (one view per page)
///                                                       │ scroll geometry
///                                                       ▼
///                                       FocusScreenState (position, settledPage)
/// ```
///
/// > Important: A new case fails to compile in `FocusPagePolicy.backgroundStyle(for:)` and
/// > `FocusSessionScreen.pageContent(for:)`, but not in `availablePages(for:)`. Until it is
/// > added there, the page never appears.
enum FocusPage: Hashable, Identifiable {
    /// The base page. Always available, and where the state falls back when another page disappears.
    case tracking
    /// The focus target page. Available only while a session is running or paused.
    case focus

    var id: Self { self }
}
