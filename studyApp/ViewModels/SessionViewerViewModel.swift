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
        try? context.delete(model: StudySession.self, where: #Predicate { $0.endedAt != nil })
        try? context.save()
    }

    func deleteSessions(_ sessions: [StudySession], context: ModelContext) {
        for session in sessions where session.endedAt != nil {
            context.delete(session)
        }
        try? context.save()
    }
}
