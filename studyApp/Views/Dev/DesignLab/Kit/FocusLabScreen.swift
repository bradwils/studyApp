//  FocusLabScreen.swift
//  studyApp
//
//  DEV ONLY — the Focus Design Lab's refinement of FocusPagerScreen: every design holds
//  the mock session and answers the pager's questions from it.

import SwiftUI

protocol FocusLabScreen: FocusPagerScreen {
    var session: FocusLabSession { get }
}

extension FocusLabScreen {
    var showsFocusPage: Bool { session.hasSession }

    var isLocked: Bool { session.isLocked }
}
