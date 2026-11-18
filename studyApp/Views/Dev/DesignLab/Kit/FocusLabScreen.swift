//  FocusLabScreen.swift
//  studyApp
//
//  DEV ONLY — the Focus Design Lab's refinement of FocusPagerScreen: every design holds
//  the mock session and answers the pager's questions from it, exactly as the real
//  FocusSessionContent answers them from StudyTrackingViewModel.

import SwiftUI

protocol FocusLabScreen: FocusPagerScreen {
    var session: FocusLabSession { get }
}

extension FocusLabScreen {
    var phase: SessionPhase { session.phase }

    var sessionID: UUID? { session.sessionID }

    // Designs lay out to the column edge themselves.
    func horizontalPadding(for page: FocusPage) -> CGFloat { 0 }
}
