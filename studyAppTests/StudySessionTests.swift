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
	@Test("In progress StudySession appears in SwiftData correctly")
	func startSessionAndCheck() throws {
		//start container setup
		let container = try ModelContainer(
			for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true) //temporary storage system
		)
		let context = container.mainContext
		//end container setup
		
		let subject = Subject(name: "testing_subject", code: "MTH2")
		context.insert(subject)
		
		let vm = StudyTrackingViewModel()
		vm.selectedSubject = subject
		vm.startSession(ctx: context)
		
		let stored = try context.fetch(FetchDescriptor<StudySession>())
		#expect(stored.count == 1)
		
		let session = try #require(stored.first)
		#expect(session.id == vm.activeSession?.id)
		#expect(session.subject?.id == subject.id)
		#expect(session.subjectName == "testing_subject")
		#expect(session.endedAt == nil)
		#expect(session.interruptionCount == 0)
		#expect(abs(session.startedAt.timeIntervalSinceNow) < 1)
	}
	
	
	
	@MainActor
	@Test("Ended StudySession appears in SwiftData correctly")
	func startAndEndSessionAndCheck() async throws { //async allows for await keyword
		let container = try ModelContainer(
			for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true) //temporary storage system
		)
		let context = container.mainContext
		
		var stored = try context.fetch(FetchDescriptor<StudySession>())

		
		
		let subject = Subject(name: "testing_subject", code: "MTH2")
		context.insert(subject)
		
		let vm = StudyTrackingViewModel()
		vm.selectedSubject = subject
		vm.startSession(ctx: context)
		
		try await Task.sleep(for: .seconds(2)) //
		vm.endSession(context: context)
		
		stored = try context.fetch(FetchDescriptor<StudySession>())
		#expect(stored.count == 1)
		
		let session = try #require(stored.first)
		let sessionSubject = try #require(session.subject)
		let endedAt = try #require(session.endedAt)
		#expect(sessionSubject.id == subject.id)
		#expect(sessionSubject.name == subject.name)
		#expect(session.subjectName == "testing_subject")
		#expect(session.endedAt != nil)
		#expect(session.interruptionCount == 0)
		#expect(endedAt.timeIntervalSince(Date.now) < 3)
		#expect(vm.ssw == nil)
		
		
	}
	
	
	
	@MainActor
	@Test("Ending a StudySession clears vm from session-related vars")
	func startAndEndSessionWithClearVars() async throws { //async allows for await keyword
		let container = try ModelContainer(
			for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true) //temporary storage system
		)
		let context = container.mainContext
		
		let subject = Subject(name: "testing_subject", code: "MTH2")
		context.insert(subject)
		
		let vm = StudyTrackingViewModel()
		vm.selectedSubject = subject
		vm.startSession(ctx: context)
		
		try await Task.sleep(for: .seconds(2)) //
		vm.endSession(context: context)
		
		let stored = try context.fetch(FetchDescriptor<StudySession>())
		#expect(stored.count == 1)
		
		let session = try #require(stored.first)
		#expect(vm.ssw == nil)
		#expect(vm.studyBreaks.isEmpty)
		#expect(vm.studySections.isEmpty)
		#expect(vm.activeSession == nil)
		#expect(vm.activePureFocusSession == nil)
	}
	
	
	
	
	
}
