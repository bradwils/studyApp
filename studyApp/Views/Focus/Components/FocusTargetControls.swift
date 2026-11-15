import SwiftUI

/// The focus duration picker and the button that starts a focus target.
///
/// ## Declaration
///
/// ```swift
/// struct FocusTargetControls: View
/// ```
///
/// The picker rolls up once a target exists; the start button is shown only until then.
struct FocusTargetControls: View {
	@Binding var duration: TimeInterval
	let hasTarget: Bool
	let canStart: Bool
	let onStart: () -> Void

	var body: some View {
		VStack(spacing: 8) {
			DurationPicker(duration: $duration)
				// Roll up like a sliding door: the picker keeps its ideal height and the frame
				// around it collapses to zero, so the lock controls below rise into its place
				// at the same rate the picker retracts. fixedSize is what keeps this stable —
				// measuring the picker and feeding that back into its own frame re-laid it out
				// on every pass and hung the main thread.
				.fixedSize(horizontal: false, vertical: true)
				.frame(height: hasTarget ? 0 : nil, alignment: .top)
				.clipped()

			if !hasTarget {
				Button("Start Focus Session") {
					withAnimation(.easeInOut(duration: 0.35)) {
						onStart()
					}
				}
				.buttonStyle(.glass)
				.disabled(!canStart)
			}
		}
	}
}

#Preview {
	@Previewable @State var duration: TimeInterval = 25 * 60
	FocusTargetControls(duration: $duration, hasTarget: false, canStart: true, onStart: {})
		.padding()
		.background(TimerGradientBackground(progress: 0, isTimerActive: false))
}
