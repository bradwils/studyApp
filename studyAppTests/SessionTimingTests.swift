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

	@Test("Pause/resume replays credit each study interval once", arguments: 0..<64)
	func replayPauseResume(trace: Int) {
		var timing = SessionTiming.started(at: t0)
		var intervals: [(start: TimeInterval, end: TimeInterval)] = []
		var runningSince: TimeInterval? = 0
		var pausedSince: TimeInterval?
		var replay = ["start@0"]

		// Every six-command pause/resume sequence shares zero-length and backwards clock steps.
		for (index, offset) in ([0, 20, 20, 120, 90, 150] as [TimeInterval]).enumerated() {
			let pause = trace & (1 << index) == 0
			replay.append("\(pause ? "pause" : "resume")@\(offset)")
			let note: Comment = "Trace \(trace): \(replay.joined(separator: " → "))"
			let previous = timing
			let date = t0.addingTimeInterval(offset)

			if pause {
				timing = timing.pausing(at: date)
				if let start = runningSince {
					intervals.append((start: start, end: offset))
					runningSince = nil
					pausedSince = offset
				} else {
					#expect(timing == previous, note)
				}
			} else {
				timing = timing.resuming(at: date)
				if runningSince == nil {
					runningSince = offset
					pausedSince = nil
				} else {
					#expect(timing == previous, note)
				}
			}

			// The oracle retains accepted intervals rather than the clock's accumulated scalar.
			let completed = intervals.reduce(0) { $0 + max(0, $1.end - $1.start) }
			#expect(timing.isRunning == (runningSince != nil), note)
			#expect(timing.elapsedAnchor == runningSince.map { t0.addingTimeInterval($0 - completed) }, note)
			if let pausedSince {
				guard case .paused(let pausedAt, _) = timing else {
					Issue.record("Expected a paused clock. Trace \(trace): \(replay.joined(separator: " → "))")
					return
				}
				#expect(pausedAt == t0.addingTimeInterval(pausedSince), note)
			}

			for delta in [-30, 0, 15, 3_600] as [TimeInterval] {
				let observation = offset + delta
				let expected = completed + (runningSince.map { max(0, observation - $0) } ?? 0)
				#expect(timing.activeElapsed(at: t0.addingTimeInterval(observation)) == expected,
						"Trace \(trace): \(replay.joined(separator: " → ")); observe@\(observation)")
			}
		}
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
