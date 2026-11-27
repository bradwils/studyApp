import Testing
import SwiftData
@testable import studyApp

import Foundation

@MainActor
struct StudyTimelineTests {

	private let origin = Date(timeIntervalSinceReferenceDate: 1_000)

	private func at(_ minutes: Double) -> Date {
		origin.addingTimeInterval(minutes * 60)
	}

	private func interval(_ start: Double, _ end: Double) -> DateInterval {
		DateInterval(start: at(start), end: at(end))
	}

	private func span(_ kind: StudyTimeKind, _ start: Double, _ end: Double) -> StudySpan {
		StudySpan(kind: kind, start: at(start), end: at(end))
	}

	@Test("Without focus blocks every section is plain study and breaks are gaps")
	func plainStudy() {
		let spans = StudyTimeline.spans(study: [interval(10, 20), interval(0, 5)], focus: [])

		#expect(spans == [span(.study, 0, 5), span(.study, 10, 20)])
	}

	@Test("A block reset before its target is focus that ended early")
	func blockEndedEarly() {
		let spans = StudyTimeline.spans(
			study: [interval(0, 30)],
			focus: [FocusWindow(interval: interval(5, 15), target: 25 * 60)]
		)

		#expect(spans == [span(.study, 0, 5), span(.focusEndedEarly, 5, 15), span(.study, 15, 30)])
	}

	@Test("A completed block counts as focus up to its target, then plain study")
	func completedBlockOverflow() {
		let spans = StudyTimeline.spans(
			study: [interval(0, 40)],
			focus: [FocusWindow(interval: interval(5, 35), target: 25 * 60)]
		)

		#expect(spans == [span(.study, 0, 5), span(.focusCompleted, 5, 30), span(.study, 30, 40)])
	}

	@Test("A break inside a block pauses it: focus resumes after the break and still totals the target")
	func completedBlockAcrossBreak() {
		let spans = StudyTimeline.spans(
			study: [interval(0, 20), interval(30, 50)],
			focus: [FocusWindow(interval: interval(10, 50), target: 25 * 60)]
		)

		#expect(spans == [
			span(.study, 0, 10), span(.focusCompleted, 10, 20),
			span(.focusCompleted, 30, 45), span(.study, 45, 50)
		])
		let expected: [StudyTimeKind: TimeInterval] = [.study: 900, .focusCompleted: 1_500]
		#expect(StudyTimeline.totals(spans) == expected)
	}

	@Test("Break time inside a block does not count towards its target")
	func breakTimeDoesNotCompleteBlock() {
		let spans = StudyTimeline.spans(
			study: [interval(0, 10), interval(30, 40)],
			focus: [FocusWindow(interval: interval(0, 40), target: 25 * 60)]
		)

		let expected: [StudyTimeKind: TimeInterval] = [.focusEndedEarly: 1_200]
		#expect(StudyTimeline.totals(spans) == expected)
	}

	@Test("A tracked session records its focus blocks and derives each kind of study time")
	func trackedSession() throws {
		let container = try ModelContainer(
			for: Schema(AppSchema.models),
			configurations: ModelConfiguration(isStoredInMemoryOnly: true)
		)
		let context = container.mainContext
		var current = origin
		let vm = StudyTrackingViewModel(now: { current })

		vm.startSession(context: context)
		current = at(5)
		#expect(vm.startFocusTarget(duration: 10 * 60, context: context))
		current = at(10)
		vm.resetFocusTarget(context: context)
		#expect(vm.startFocusTarget(duration: 10 * 60, context: context))
		current = at(15)
		vm.pauseSession(context: context)
		current = at(20)
		vm.resumeSession(context: context)
		current = at(30)
		vm.finishSession(context: context)

		let session = try #require(try ModelContext(container).fetch(FetchDescriptor<StudySession>()).first)
		#expect(session.focusBlocks.count == 2)
		#expect(session.focusBlocks.allSatisfy { $0.endedAt != nil })

		let spans = StudyTimeline.spans(for: session, now: current)
		#expect(spans == [
			span(.study, 0, 5), span(.focusEndedEarly, 5, 10), span(.focusCompleted, 10, 15),
			span(.focusCompleted, 20, 25), span(.study, 25, 30)
		])
	}
}
