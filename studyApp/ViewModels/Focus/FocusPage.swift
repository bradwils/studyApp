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
/// - ``FocusPagerScaffold`` reconciles the state when the phase changes; each ``FocusPagerScreen`` maps every page to its header and content.
///
/// ```text
/// SessionPhase ─▶ FocusPagePolicy ─▶ [FocusPage] ─▶ FocusScreenState
///                                                       │ pages, scrolledPage
///                                                       ▼
/// FocusPagerScreen ─ header/content(for:) ─▶ FocusPager (one view per page)
///                                                       │ scroll geometry
///                                                       ▼
///                                       FocusScreenState (position, settledPage)
/// ```
///
/// > Important: A new case fails to compile in `FocusPagePolicy.backgroundStyle(for:)` and
/// > every `FocusPagerScreen.header(for:_:)` and `content(for:_:)`, but not in `availablePages(for:)`. Until it is
/// > added there, the page never appears.
enum FocusPage: Hashable, Identifiable {
    /// The base page. Always available, and where the state falls back when another page disappears.
    case tracking
    /// The focus target page. Available only while a session is running or paused.
    case focus

    var id: Self { self }
}
