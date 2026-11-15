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
enum FocusPage: Hashable, Identifiable {
    case tracking
    case focus

    var id: Self { self }
}
