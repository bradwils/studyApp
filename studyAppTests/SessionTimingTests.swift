import Testing
import Foundation
@testable import studyApp

struct SessionTimingTests {
	private let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

	@Test("Pausing freezes active elapsed time")
	func pauseFreezes() {
		let paused = SessionTiming.started(at: t0).pausing(at: t0.addingTimeInterval(100))
		#expect(paused.activeElapsed(at: t0.addingTimeInterval(100)) == 100)
		#expect(paused.activeElapsed(at: t0.addingTimeInterval(500)) == 100)
		#expect(paused.elapsedAnchor == nil)
	}

	@Test("Resuming continues from the accumulated time")
	func resumeContinues() {
		let resumed = SessionTiming.started(at: t0)
			.pausing(at: t0.addingTimeInterval(100))
			.resuming(at: t0.addingTimeInterval(160))
		#expect(resumed.activeElapsed(at: t0.addingTimeInterval(160)) == 100)
		#expect(resumed.activeElapsed(at: t0.addingTimeInterval(190)) == 130)
		#expect(resumed.elapsedAnchor == t0.addingTimeInterval(60))
	}

	@Test("A backwards clock never produces negative elapsed time")
	func backwardsClockClamps() {
		let timing = SessionTiming.started(at: t0)
		#expect(timing.activeElapsed(at: t0.addingTimeInterval(-50)) == 0)
	}

	@Test("FocusTarget rejects invalid durations")
	func targetRejectsInvalid() {
		for duration in [0, -1, .nan, .infinity, 8 * 3600 + 59 * 60 + 1] as [TimeInterval] {
			#expect(FocusTarget(duration: duration, activeElapsedAtStart: 0) == nil)
		}
		#expect(FocusTarget(duration: 1500, activeElapsedAtStart: 0) != nil)
	}

	@Test("FocusTarget progress freezes across a pause")
	func targetFreezesAcrossPause() throws {
		let target = try #require(FocusTarget(duration: 100, activeElapsedAtStart: 20))
		let timing = SessionTiming.started(at: t0)
			.pausing(at: t0.addingTimeInterval(70))
		let before = target.progress(sessionActiveElapsed: timing.activeElapsed(at: t0.addingTimeInterval(70)))
		let during = target.progress(sessionActiveElapsed: timing.activeElapsed(at: t0.addingTimeInterval(700)))
		#expect(before == 0.5)
		#expect(during == before)
		#expect(target.remaining(sessionActiveElapsed: 500) == 0)
	}
}
