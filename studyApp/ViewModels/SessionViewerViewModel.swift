//
//  SessionViewerViewModel.swift
//  studyApp
//
//  Created by brad wils on 20/7/26.
//
import Foundation
import SwiftData

@Observable
final class SessionViewerViewModel {
    //ask for a context with your function
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

    func deleteSessions(_ sessions: [StudySession], activeSessionID: UUID?, context: ModelContext) {
        for session in sessions where session.id != activeSessionID {
            context.delete(session)
        }
        try? context.save()
    }
}
