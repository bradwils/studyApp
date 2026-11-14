import SwiftUI

/// The start, pause and resume button, plus End Session while paused.
///
/// ## Declaration
///
/// ```swift
/// struct SessionControls: View
/// ```
///
/// Owns the glass morph between the two buttons; the callbacks run inside that animation,
/// which is skipped under Reduce Motion.
struct SessionControls: View {
	let phase: SessionPhase
	let onPrimary: () -> Void
	let onFinish: () -> Void

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	@Namespace private var glassNamespace

	var body: some View {
		GlassEffectContainer(spacing: 16) {
			// Both buttons sit directly next to each other (no stretching
			// spacer between them) so the container's fluid glass blend can
			// actually reach across the gap while the end button inserts/removes —
			// that adjacency is what sells the morph, not a manual transition.
			HStack(spacing: 16) {
				Button {
					withMorphAnimation(onPrimary)
				} label: {
					// Sizing/font applied to the content BEFORE the button style,
					// with .glassEffectID chained immediately after it — that order is
					// what lets the container track this as the actual glass surface.
					Text(mainButtonLabel)
						.id(mainButtonLabel)
						.transition(.blurReplace)
						.font(.body)
						.padding(.horizontal)  //padding for start button, makes button wider than text
				}
				.buttonStyle(.glassProminent)
				.glassEffectID("startPauseButton", in: glassNamespace)
				.accessibilityIdentifier("startPauseButton")

				if phase == .paused {
					Button {
						withMorphAnimation(onFinish)
					} label: {
						Text("End Session")
							.font(.body)
							.padding(.horizontal)  //padding for start button, makes button wider than text
					}
					.buttonStyle(.glass)
					.glassEffectID("endSessionButton", in: glassNamespace)
					.accessibilityIdentifier("endSessionButton")
				}
			}
		}
	}

	private var mainButtonLabel: String {
		switch phase {
		case .idle:
			return "Start"
		case .paused:
			return "Resume"
		case .running:
			return "Pause"
		}
	}

	// Glass morph + label swap; skipped entirely under Reduce Motion.
	private func withMorphAnimation(_ changes: () -> Void) {
		if reduceMotion {
			changes()
		} else {
			withAnimation(.smooth(duration: 0.4)) {
				changes()
			}
		}
	}
}

#Preview {
	SessionControls(phase: .paused, onPrimary: {}, onFinish: {})
		.padding()
		.background(Color.purple.opacity(0.4))
}
