//
//  SessionViewerViewModel.swift
//  studyApp
//
//  Created by brad wils on 20/7/26.
//
import Combine
import Foundation
import SwiftData

@Observable
final class SessionViewerViewModel {
    //ask for a context with your function
    func removeAllSessions(context: ModelContext) {
        // Batch delete(model:) bypasses relationship delete rules and can fail on inverse constraints,
        // so delete each fetched session to get the cascade to breaks/sections/location.
        let sessions = (try? context.fetch(FetchDescriptor<StudySession>())) ?? []
        deleteSessions(sessions, context: context)
    }

    func deleteSessions(_ sessions: [StudySession], context: ModelContext) {
        for session in sessions {
            context.delete(session)
        }
        try? context.save()
    }
    
    
    init() {
    }
}
