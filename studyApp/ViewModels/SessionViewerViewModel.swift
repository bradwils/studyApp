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
    func removeAllSessions(context: ModelContext) {
        // Fetch/delete individually so cascades apply; active sessions must survive Clear All.
        let descriptor = FetchDescriptor<StudySession>(predicate: #Predicate { $0.endedAt != nil })
        let sessions = (try? context.fetch(descriptor)) ?? []
        deleteSessions(sessions, context: context)
    }

    func deleteSessions(_ sessions: [StudySession], context: ModelContext) {
        for session in sessions where session.endedAt != nil {
            context.delete(session)
        }
        try? context.save()
    }
}
