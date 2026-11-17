//  FocusLabDesign.swift
//  studyApp
//
//  DEV ONLY — registry of the Focus Design Lab screens. Adding a design means adding a
//  case here; the dev menu and the lab bar both read from allCases.

import SwiftUI

enum FocusLabDesign: String, CaseIterable, Identifiable {
    case margin
    case daylight
    case strata
    case vellum
    case tape
    case stars

    var id: String { rawValue }

    var title: String {
        switch self {
        case .margin: return "Margin"
        case .daylight: return "Daylight"
        case .strata: return "Strata"
        case .vellum: return "Vellum"
        case .tape: return "Tape"
        case .stars: return "Stars"
        }
    }

    var summary: String {
        switch self {
        case .margin: return "Muted notebook page. A highlighter stroke tracks time; focus wipes in as an ink page."
        case .daylight: return "Warm and bright. A sun on the day's arc comes forward and rises with the focus block."
        case .strata: return "The session settles in flat bands of colour. Focus zooms into the band being laid now."
        case .vellum: return "Five translucent sheets. Fanned while tracking, they stack behind the timer and bloom as you focus."
        case .tape: return "A measuring tape slides under a needle. Swipe across: it zooms out to show the whole focus block."
        case .stars: return "A night sky you fill in. The sky turns behind a constellation drawn as the block runs; pausing brings dawn."
        }
    }

    /// Forced on the cover so the status bar and the lab bar read correctly over the design.
    var colorScheme: ColorScheme? {
        switch self {
        case .margin: return .light
        case .daylight: return .light
        case .strata: return .light
        case .vellum: return .light
        case .tape: return .light
        case .stars: return .dark
        }
    }

    @ViewBuilder
    func screen(session: FocusLabSession) -> some View {
        switch self {
        case .margin: FocusPagerScaffold(screen: MarginDesign(session: session))
        case .daylight: FocusPagerScaffold(screen: DaylightDesign(session: session))
        case .strata: FocusPagerScaffold(screen: StrataDesign(session: session))
        case .vellum: FocusPagerScaffold(screen: VellumDesign(session: session))
        case .tape: FocusPagerScaffold(screen: TapeDesign(session: session))
        case .stars: FocusPagerScaffold(screen: StarsDesign(session: session))
        }
    }
}
