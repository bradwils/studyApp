//  FocusLabDesign.swift
//  studyApp
//
//  DEV ONLY — registry of the Focus Design Lab screens. Adding a design means adding a
//  case here; the dev menu and the lab bar both read from allCases.

import SwiftUI

enum FocusLabDesign: String, CaseIterable, Identifiable {
    case reference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reference: return "Reference"
        }
    }

    var summary: String {
        switch self {
        case .reference: return "The current screen rebuilt on the lab kit, for comparison."
        }
    }

    /// Forced on the cover so the status bar and the lab bar read correctly over the design.
    var colorScheme: ColorScheme? {
        switch self {
        case .reference: return nil
        }
    }

    @ViewBuilder
    func screen(session: FocusLabSession) -> some View {
        switch self {
        case .reference: ReferenceDesign(session: session)
        }
    }
}
