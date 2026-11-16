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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reference: return "Reference"
        case .margin: return "Margin"
        case .daylight: return "Daylight"
        }
    }

    var summary: String {
        switch self {
        case .reference: return "The current screen rebuilt on the lab kit, for comparison."
        case .margin: return "Muted notebook page. A highlighter stroke tracks time; focus wipes in as an ink page."
        case .daylight: return "Warm and bright. A sun on the day's arc comes forward and rises with the focus block."
        }
    }

    /// Forced on the cover so the status bar and the lab bar read correctly over the design.
    var colorScheme: ColorScheme? {
        switch self {
        case .reference: return nil
        case .margin: return .light
        case .daylight: return .light
        }
    }

    @ViewBuilder
    func screen(session: FocusLabSession) -> some View {
        switch self {
        case .reference: ReferenceDesign(session: session)
        case .margin: MarginDesign(session: session)
        case .daylight: DaylightDesign(session: session)
        }
    }
}
