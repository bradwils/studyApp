//  StudyTrackingViewModel.swift
//  studyApp

import Foundation
import SwiftData
import os

// Failed saves leave the in-memory transition pending and expose a save error.
@Observable
final class StudyTrackingViewModel {
    private var activeSession: StudySession?
    private(set) var focusTarget: FocusTarget?
    private(set) var selectedSubject: Subject?
    private(set) var saveErrorMessage: String?

    private var timing: SessionTiming?
    private let now: () -> Date
    private let logger = Logger(subsystem: "com.studyApp", category: "studyTracking")

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    // MARK: - Facts

    var phase: SessionPhase {
        switch timing {
        case nil: .idle
        case .running?: .running
        case .paused?: .paused
        }
    }

    var activeSessionID: UUID? { activeSession?.id }

    var hasActiveSession: Bool { activeSession != nil }

    var canSelectSubject: Bool { !hasActiveSession }

    var hasFocusTarget: Bool { focusTarget != nil }

    var timerDisplay: TimerDisplay {
        guard let timing else { return .idle }
        switch timing {
        case .paused(let pausedAt, _):
            return .breakElapsed(since: pausedAt)
        case .running:
            guard let anchor = timing.elapsedAnchor else { return .idle }
            guard let focusTarget else { return .elapsed(since: anchor) }
            let deadline = anchor.addingTimeInterval(focusTarget.activeElapsedAtStart + focusTarget.duration)
            return .countdown(until: deadline, total: focusTarget.duration)
        }
    }

    var activeSubjectName: String? { activeSession?.subjectName }

    var displayedSubjectCode: String? {
        hasActiveSession ? activeSession?.subject?.code : selectedSubject?.code
    }

    func activeElapsed(at date: Date) -> TimeInterval {
        timing?.activeElapsed(at: date) ?? 0
    }

    func focusProgress(at date: Date) -> Double {
        focusTarget?.progress(sessionActiveElapsed: activeElapsed(at: date)) ?? 0
    }

    // MARK: - Commands

    func selectSubject(_ subject: Subject?) {
        guard canSelectSubject else { return }
        selectedSubject = subject
    }

    func startSession(context: ModelContext) {
        let now = now()
        guard phase == .idle else { return }

        let session = StudySession(
            subject: selectedSubject,
            subjectName: selectedSubject?.name,
            startedAt: now,
            breaks: [],
            sections: [StudySection(startedAt: now)]
        )
        context.insert(session)
        activeSession = session
        timing = .started(at: now)
        save(context)
    }

    func pauseSession(context: ModelContext) {
        let now = now()
        guard let session = activeSession, let timing, timing.isRunning else { return }

        closeOpenSection(of: session, at: now)
        session.breaks = (session.breaks ?? []) + [StudyBreak(startedAt: now)]
        session.lastPausedAt = now
        self.timing = timing.pausing(at: now)
        save(context)
    }

    func resumeSession(context: ModelContext) {
        let now = now()
        guard let session = activeSession, let timing, !timing.isRunning else { return }

        closeOpenBreak(of: session, at: now)
        session.sections = (session.sections ?? []) + [StudySection(startedAt: now)]
        session.lastPausedAt = nil
        self.timing = timing.resuming(at: now)
        save(context)
    }

    func finishSession(context: ModelContext) {
        let now = now()
        guard let session = activeSession else { return }

        closeOpenSection(of: session, at: now)
        closeOpenBreak(of: session, at: now)
        session.lastPausedAt = nil
        session.endedAt = now
        session.totalBreakDuration = (session.breaks ?? []).reduce(0) { $0 + $1.duration }
        clearActiveState()
        save(context)
    }

    func cancelSession(context: ModelContext) {
        guard let session = activeSession else { return }

        context.delete(session)
        clearActiveState()
        save(context)
    }

    @discardableResult
    func startFocusTarget(duration: TimeInterval) -> Bool {
        let now = now()
        guard let timing, timing.isRunning, focusTarget == nil,
              let target = FocusTarget(duration: duration, activeElapsedAtStart: timing.activeElapsed(at: now))
        else { return false }

        focusTarget = target
        return true
    }

    func resetFocusTarget() {
        focusTarget = nil
    }

    func addInterruption() {
        activeSession?.interruptionCount += 1
    }

    func dismissSaveError() {
        saveErrorMessage = nil
    }

    // MARK: - Private

    private func clearActiveState() {
        activeSession = nil
        timing = nil
        focusTarget = nil
    }

    private func closeOpenSection(of session: StudySession, at date: Date) {
        session.sections?.last(where: { $0.endedAt == nil })?.endedAt = date
    }

    private func closeOpenBreak(of session: StudySession, at date: Date) {
        session.breaks?.last(where: { $0.endedAt == nil })?.endedAt = date
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("Saving a session transition failed: \(error.localizedDescription)")
            saveErrorMessage = "Your session change couldn't be saved. It will be retried automatically."
        }
    }
}
