//
//  SessionViewerViewModel.swift
//  studyApp
//
//  Created by brad wils on 20/7/26.
//
import Foundation
import SwiftData

/// Deletes session history while protecting the session the app currently owns.
///
/// ## Declaration
///
/// ```swift
/// @Observable final class SessionViewerViewModel
/// ```
///
/// Both deletion paths use the tracking owner's session ID. An unfinished
/// record from an earlier app run is eligible for deletion.
@Observable
final class SessionViewerViewModel {
    /// Deletes all sessions except the one matching `activeSessionID`, or all sessions when it is `nil`.
    func removeAllSessions(activeSessionID: UUID?, context: ModelContext) {
        // Fetch/delete individually so cascades apply; only the currently owned session must survive.
        let descriptor: FetchDescriptor<StudySession>
        if let activeSessionID {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.id != activeSessionID })
        } else {
            descriptor = FetchDescriptor()
        }
        let sessions = (try? context.fetch(descriptor)) ?? []
        deleteSessions(sessions, activeSessionID: activeSessionID, context: context)
    }

    /// Deletes the selected sessions, skipping any record that matches `activeSessionID`.
    func deleteSessions(_ sessions: [StudySession], activeSessionID: UUID?, context: ModelContext) {
        for session in sessions where session.id != activeSessionID {
            context.delete(session)
        }
        try? context.save()
    }
}
