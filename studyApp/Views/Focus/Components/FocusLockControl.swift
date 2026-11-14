import SwiftUI

struct FocusLockControl: View {
	let isLocked: Bool
	let onLockChange: (Bool) -> Void

	private let unlockTapsRequired = 10
	// Ignore accidental double-taps when counting unlock confirmations.
	private let unlockTapMinInterval: TimeInterval = 0.15

	@State private var unlockTapCount = 0
	@State private var lastUnlockTapAt: Date = .distantPast
	@State private var unlockShakeTrigger: CGFloat = 0

	var body: some View {
		//lock button: PAID FEATURE
		Button(action: handleLockTap) {
			HStack(spacing: 8) {
				Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
					.contentTransition(.symbolEffect(.replace.magic(fallback: .offUp.byLayer), options: .nonRepeating))

				Text(isLocked ? "Unlock State" : "Lock State")
			}
		}
		.buttonStyle(.glass)
		.accessibilityHint(isLocked ? "Tap ten times to unlock" : "Hides the tab bar and disables swiping between pages")
		.modifier(ShakeEffect(animatableData: unlockShakeTrigger))
		.sensoryFeedback(.impact(weight: .light), trigger: unlockShakeTrigger)
		.onChange(of: isLocked) { _, locked in
			// A freshly engaged lock gets a fresh set of confirmation taps.
			if locked {
				unlockTapCount = 0
			}
		}
	}

	private func handleLockTap() {
		guard isLocked else {
			withAnimation(.easeInOut(duration: 0.5)) {
				onLockChange(true)
			}
			return
		}

		let now = Date()
		guard now.timeIntervalSince(lastUnlockTapAt) >= unlockTapMinInterval else { return }
		lastUnlockTapAt = now

		unlockTapCount += 1
		guard unlockTapCount < unlockTapsRequired else {
			withAnimation(.easeInOut(duration: 0.5)) {
				onLockChange(false)
			}
			return
		}

		withAnimation(.linear(duration: 0.25)) {
			unlockShakeTrigger += 1
		}
	}
}

#Preview {
	@Previewable @State var isLocked = false
	FocusLockControl(isLocked: isLocked) { isLocked = $0 }
		.padding()
		.background(TimerGradientBackground(progress: 0, isTimerActive: false))
}
