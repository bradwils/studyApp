//
//  StudySessionTests.swift
//  studyApp
//
//  Created by brad wils on 19/10/26.
//
import Testing
import SwiftData
@testable import studyApp

import Foundation

struct StudySessionTests {

	@MainActor
	private func makeContext() throws -> ModelContext {
		let container = try ModelContainer(
			for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true)
		)
		return container.mainContext
	}

	@MainActor
	@Test("In progress StudySession appears in SwiftData correctly")
	func startSessionAndCheck() throws {
		let context = try makeContext()
		let start = Date(timeIntervalSinceReferenceDate: 1_000)

		let subject = Subject(name: "testing_subject", code: "MTH2")
		context.insert(subject)

		let vm = StudyTrackingViewModel(now: { start })
		vm.selectSubject(subject)
		vm.startSession(context: context)

		let stored = try context.fetch(FetchDescriptor<StudySession>())
		#expect(stored.count == 1)

		let session = try #require(stored.first)
		#expect(session.id == vm.activeSession?.id)
		#expect(session.subject?.id == subject.id)
		#expect(session.subjectName == "testing_subject")
		#expect(session.endedAt == nil)
		#expect(session.interruptionCount == 0)
		#expect(session.startedAt == start)
		#expect(session.sections?.count == 1)
		#expect(session.sections?.first?.endedAt == nil)
		#expect(vm.phase == .running)
	}

	@MainActor
	@Test("Ended StudySession records closed sections and breaks")
	func startAndEndSessionAndCheck() throws {
		let context = try makeContext()
		var current = Date(timeIntervalSinceReferenceDate: 1_000)

		let subject = Subject(name: "testing_subject", code: "MTH2")
		context.insert(subject)

		let vm = StudyTrackingViewModel(now: { current })
		vm.selectSubject(subject)
		vm.startSession(context: context)

		current.addTimeInterval(600)
		vm.pauseSession(context: context)
		current.addTimeInterval(120)
		vm.resumeSession(context: context)
		current.addTimeInterval(300)
		vm.finishSession(context: context)

		let stored = try context.fetch(FetchDescriptor<StudySession>())
		#expect(stored.count == 1)

		let session = try #require(stored.first)
		#expect(session.subject?.id == subject.id)
		#expect(session.endedAt == current)

		let sections = try #require(session.sections)
		#expect(sections.count == 2)
		#expect(sections.allSatisfy { $0.endedAt != nil })
		#expect(sections.reduce(0) { $0 + $1.duration } == 900)

		let breaks = try #require(session.breaks)
		#expect(breaks.count == 1)
		#expect(breaks.first?.endedAt != nil)
		#expect(breaks.first?.duration == 120)
		#expect(session.totalBreakDuration == 120)
		#expect(session.lastPausedAt == nil)
	}

	@MainActor
	@Test("Finishing while paused closes the final break once")
	func finishWhilePaused() throws {
		let context = try makeContext()
		var current = Date(timeIntervalSinceReferenceDate: 1_000)

		let vm = StudyTrackingViewModel(now: { current })
		vm.startSession(context: context)
		current.addTimeInterval(60)
		vm.pauseSession(context: context)
		vm.pauseSession(context: context)
		current.addTimeInterval(30)
		vm.finishSession(context: context)
		vm.finishSession(context: context)

		let session = try #require(try context.fetch(FetchDescriptor<StudySession>()).first)
		#expect(session.breaks?.count == 1)
		#expect(session.breaks?.first?.duration == 30)
		#expect(session.sections?.count == 1)
		#expect(session.sections?.first?.duration == 60)
		#expect(session.totalBreakDuration == 30)
	}

	@MainActor
	@Test("Finishing a StudySession clears the view model's session state")
	func startAndEndSessionWithClearVars() throws {
		let context = try makeContext()
		var current = Date(timeIntervalSinceReferenceDate: 1_000)

		let vm = StudyTrackingViewModel(now: { current })
		vm.startSession(context: context)
		current.addTimeInterval(10)
		#expect(vm.startFocusTarget(duration: 300))
		vm.finishSession(context: context)

		#expect(try context.fetch(FetchDescriptor<StudySession>()).count == 1)
		#expect(vm.activeSession == nil)
		#expect(vm.focusTarget == nil)
		#expect(vm.phase == .idle)
		#expect(vm.timerDisplay == .idle)
	}
}
