import SwiftUI

struct SessionControls: View {
    let phase: SessionPhase
    let onPrimary: () -> Void
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var glassNamespace

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            // Adjacent buttons let the container blend glass as the end button appears.
            HStack(spacing: 16) {
                Button {
                    withMorphAnimation(onPrimary)
                } label: {
                    // Style the content before assigning its glass ID so the surface is tracked.
                    Text(mainButtonLabel)
                        .id(mainButtonLabel)
                        .transition(.blurReplace)
                        .font(.body)
                        .padding(.horizontal)
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
                            .padding(.horizontal)
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
