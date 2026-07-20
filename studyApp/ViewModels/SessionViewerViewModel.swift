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
        try? context.delete(model: StudySession.self)
    }
    
    
    init() {
    }
}
