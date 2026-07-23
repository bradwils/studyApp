//  StudyTrackingViewModel.swift
//  studyApp
//
//  Session Store / Logic for study tracking.

import Foundation
import SwiftData

@Observable
final class StudyTrackingViewModel {
    var activeSession: StudySession?
    var selectedSubject: Subject?

    private let breakThreshold: TimeInterval = 60 * 3

    func startSession(subject: Subject? = nil, subjectName: String? = nil, context: ModelContext) {
        let now = Date()
        let session = StudySession(
            subject: subject ?? Subject(name: "Untitled", code: ""),
            subjectName: subjectName,
            startedAt: now,
            endedAt: nil,
            lastPausedAt: nil,
            activeDuration: 0,
            totalBreakDuration: nil,
            breaks: [],
            friends: [],
            location: nil,
            studyScore: nil,
            notes: nil,
            interruptionCount: 0
        )
        context.insert(session)
        try? context.save()
        activeSession = session
    }

    func pauseSession(context: ModelContext) {
        guard let session = activeSession, session.endedAt == nil else { return }
        let now = Date()
        session.lastPausedAt = now
        try? context.save()
    }

    func resumeSession(context: ModelContext) {
        guard let session = activeSession, let pausedAt = session.lastPausedAt else { return }
        let now = Date()
        let pausedDuration = now.timeIntervalSince(pausedAt)

        if pausedDuration >= breakThreshold {
            let newBreak = StudyBreak(startedAt: pausedAt, endedAt: now)
            if session.breaks == nil {
                session.breaks = []
            }
            session.breaks?.append(newBreak)
        }

        session.lastPausedAt = nil
        try? context.save()
    }

    func endSession(score: Int? = nil, friends: [String] = [], locationDescription: String? = nil, context: ModelContext) {
        guard let session = activeSession else { return }
        let now = Date()

        session.endedAt = now
        session.studyScore = score
        session.lastPausedAt = nil

        if !friends.isEmpty {
            session.friends = friends
        }

        if let locationDescription = locationDescription {
            if let existingLocation = session.location {
                existingLocation.locationDescription = locationDescription
            } else {
                let newLocation = SessionLocation(locationDescription: locationDescription, latitude: nil, longitude: nil, locationLabel: "")
                session.location = newLocation
            }
        }

        try? context.save()
        activeSession = nil
    }

    func updateActiveSessionSubject(_ subject: Subject?, context: ModelContext) {
        guard let session = activeSession else { return }
        session.subject = subject
        session.subjectName = subject?.name
        try? context.save()
    }

    func cancelActiveSession() {
        activeSession = nil
    }

    func addInterruption(context: ModelContext) {
        guard let session = activeSession else { return }
        session.interruptionCount += 1
        try? context.save()
    }

    func updateSubjectSelection(_ subject: Subject?) {
        guard activeSession == nil else { return }
        selectedSubject = subject
    }

    func hasAlreadyStudiedToday() -> Bool {
        return false
    }
}
