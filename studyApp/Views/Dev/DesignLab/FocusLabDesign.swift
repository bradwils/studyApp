//  FocusLabDesign.swift
//  studyApp
//
//  DEV ONLY — registry of the Focus Design Lab screens. Adding a design means adding a
//  case here; the dev menu and the lab bar both read from allCases.

import SwiftUI

enum FocusLabDesign: String, CaseIterable, Identifiable {
    case reference
    case margin
    case daylight
    case tide
    case dial
    case lamp
    case float
    case poster
    case strata
    case vellum
    case tape

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reference: return "Reference"
        case .margin: return "Margin"
        case .daylight: return "Daylight"
        case .tide: return "Tide"
        case .dial: return "Dial"
        case .lamp: return "Lamp"
        case .float: return "Float"
        case .poster: return "Poster"
        case .strata: return "Strata"
        case .vellum: return "Vellum"
        case .tape: return "Tape"
        }
    }

    var summary: String {
        switch self {
        case .reference: return "The current screen rebuilt on the lab kit, for comparison."
        case .margin: return "Muted notebook page. A highlighter stroke tracks time; focus wipes in as an ink page."
        case .daylight: return "Warm and bright. A sun on the day's arc comes forward and rises with the focus block."
        case .tide: return "Time as a water level. The timer changes colour along the wave where the tide covers it."
        case .dial: return "Watch face. One ring turns from a hairline hour dial into a bold focus band on cobalt."
        case .lamp: return "A desk at night. The pool of lamplight closes in on the timer as you move to focus."
        case .float: return "Native glass on a subject-coloured field. One glass sheet draws in from a slab to a circle."
        case .poster: return "Flat colour and heavy type. The numerals travel and grow to fill the screen, then fill with orange."
        case .strata: return "The session settles in flat bands of colour. Focus zooms into the band being laid now."
        case .vellum: return "Five translucent sheets. Fanned while tracking, they stack behind the timer and bloom as you focus."
        case .tape: return "A measuring tape slides under a needle. Swipe up: it zooms out to show the whole focus block."
        }
    }

    /// Forced on the cover so the status bar and the lab bar read correctly over the design.
    var colorScheme: ColorScheme? {
        switch self {
        case .reference: return nil
        case .margin: return .light
        case .daylight: return .light
        case .tide: return .light
        case .dial: return .light
        case .lamp: return .dark
        case .float: return .light
        case .poster: return .light
        case .strata: return .light
        case .vellum: return .light
        case .tape: return .light
        }
    }

    @ViewBuilder
    func screen(session: FocusLabSession) -> some View {
        switch self {
        case .reference: ReferenceDesign(session: session)
        case .margin: MarginDesign(session: session)
        case .daylight: DaylightDesign(session: session)
        case .tide: TideDesign(session: session)
        case .dial: DialDesign(session: session)
        case .lamp: LampDesign(session: session)
        case .float: FloatDesign(session: session)
        case .poster: PosterDesign(session: session)
        case .strata: StrataDesign(session: session)
        case .vellum: VellumDesign(session: session)
        case .tape: TapeDesign(session: session)
        }
    }
}
