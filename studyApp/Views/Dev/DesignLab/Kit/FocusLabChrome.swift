//  FocusLabChrome.swift
//  studyApp
//
//  DEV ONLY — lets a design whose two pages differ in brightness tell the host which
//  colour scheme the status bar and lab bar should take at this point in the swipe.

import SwiftUI

@Observable
final class FocusLabChrome {
    var scheme: ColorScheme?
}

extension View {
    // nil hands the choice back to the system appearance.
    func focusLabChrome(_ scheme: ColorScheme?) -> some View {
        modifier(FocusLabChromeModifier(scheme: scheme))
    }
}

private struct FocusLabChromeModifier: ViewModifier {

    // Optional so a design previewed outside FocusLabHost doesn't trap on a missing environment object.
    @Environment(FocusLabChrome.self) private var chrome: FocusLabChrome?

    let scheme: ColorScheme?

    func body(content: Content) -> some View {
        content
            .onAppear { chrome?.scheme = scheme }
            .onChange(of: scheme) { _, newScheme in
                chrome?.scheme = newScheme
            }
    }
}
