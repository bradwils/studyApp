import SwiftUI

/// Simplified single-screen focus surface with an ambient background.
struct StudyTrackingView: View {
    @StateObject private var controller = StudyTrackingController()
    @Namespace private var actionNamespace

    var body: some View {
        ZStack {
            AmbientGlowBackground()
            VStack(spacing: 22) {
                header
                TimerTicketView(
                    elapsed: controller.elapsed,
                    subject: controller.subject,
                    statusText: controller.statusText,
                    breakCount: controller.breakCount,
                    pausedDuration: controller.pausedDuration,
                    breakLogged: controller.breakLoggedDuringPause,
                    state: controller.state
                )
                FocusMetricGrid(metrics: metricItems)
                Spacer(minLength: 8)
                controls
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current subject")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(controller.subject)
                    .font(.title2.weight(.semibold))
                    .contentTransition(.opacity)
                Text(controller.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                ForEach(controller.subjectOptions, id: \.self) { subject in
                    Button(subject) {
                        controller.setSubject(subject)
                    }
                }
            } label: {
                Image(systemName: "books.vertical.fill")
                    .imageScale(.large)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var metricItems: [FocusMetricItem] {
        [
            FocusMetricItem(id: "elapsed", icon: "clock", title: "Elapsed", value: controller.elapsed.formattedClock),
            FocusMetricItem(
                id: "pause",
                icon: "pause.circle",
                title: controller.state == .paused ? "Pause time" : "Paused",
                value: controller.state == .paused ? controller.pausedDuration.formattedClock : "--"
            ),
            FocusMetricItem(id: "breaks", icon: "cup.and.saucer.fill", title: "Breaks", value: "\(controller.breakCount)"),
            FocusMetricItem(
                id: "last",
                icon: "sparkles",
                title: "Last session",
                value: controller.completedSession?.totalDuration.formattedClock ?? "--"
            )
        ]
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    controller.togglePrimaryAction()
                }
            } label: {
                FocusActionLabel(
                    title: primaryActionTitle,
                    subtitle: primaryActionSubtitle,
                    icon: primaryActionIcon
                )
            }
            .buttonStyle(FocusActionButtonStyle(namespace: actionNamespace, colors: primaryActionColors))

            if controller.state == .paused {
                Button {
                    controller.endSession()
                } label: {
                    Label("End & log session", systemImage: "stop.circle")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.7))
            }

            FocusBreakHint(
                state: controller.state,
                pausedDuration: controller.pausedDuration,
                breakLogged: controller.breakLoggedDuringPause
            )
        }
    }

    private var primaryActionTitle: String {
        switch controller.state {
        case .idle, .finished:
            return "Start focus"
        case .running:
            return "Pause timer"
        case .paused:
            return "Resume focus"
        }
    }

    private var primaryActionSubtitle: String {
        switch controller.state {
        case .idle:
            return "Ticket starts counting up right away"
        case .running:
            return "Pause anytime — 3 min logs a break"
        case .paused:
            return controller.breakLoggedDuringPause ?
                "Break logged • \(controller.pausedDuration.formattedClock)" :
                "Paused \(controller.pausedDuration.formattedClock)"
        case .finished:
            return "Start another focused ticket"
        }
    }

    private var primaryActionIcon: String {
        switch controller.state {
        case .idle, .finished, .paused:
            return "play.fill"
        case .running:
            return "pause.fill"
        }
    }

    private var primaryActionColors: [Color] {
        switch controller.state {
        case .running:
            return [Color.orange, Color.pink]
        case .paused:
            return [Color.blue, Color.purple]
        case .idle, .finished:
            return [Color.green, Color.mint]
        }
    }
}

// MARK: - Components

struct TimerTicketView: View {
    var elapsed: TimeInterval
    var subject: String
    var statusText: String
    var breakCount: Int
    var pausedDuration: TimeInterval
    var breakLogged: Bool
    var state: StudyTrackingController.State

    private var timerText: String { elapsed.formattedClock }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus ticket")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.white.opacity(0.7))
                    Text(subject)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                }
                Spacer()
                Text(statusText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.trailing)
            }

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
                .overlay(
                    HStack(spacing: 6) {
                        ForEach(0..<22, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 3, height: 3)
                        }
                    }
                )

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(timerText)
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Label(stateLabel, systemImage: stateIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 120)
                    .overlay(
                        VStack(spacing: 6) {
                            ForEach(0..<8, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 2, height: 2)
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: 10) {
                    Label("Breaks logged", systemImage: "cup.and.saucer.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(breakCount)")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Divider()
                        .overlay(Color.white.opacity(0.2))
                    Label("Pause time", systemImage: "pause.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(state == .paused ? pausedDuration.formattedClock : "--")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.55),
                            Color.purple.opacity(0.5),
                            Color.indigo.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [8, 10]))
        )
        .overlay(
            HStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.black.opacity(0.3)))
                Spacer()
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
            .padding(.horizontal, -12)
        )
    }

    private var stateLabel: String {
        switch state {
        case .idle:
            return "Ready"
        case .running:
            return "Counting up"
        case .paused:
            return breakLogged ? "Break logged" : "Paused"
        case .finished:
            return "Session saved"
        }
    }

    private var stateIcon: String {
        switch state {
        case .idle:
            return "play.fill"
        case .running:
            return "waveform.path"
        case .paused:
            return breakLogged ? "cup.and.saucer.fill" : "pause.fill"
        case .finished:
            return "checkmark"
        }
    }
}

struct FocusMetricGrid: View {
    var metrics: [FocusMetricItem]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(metrics) { metric in
                FocusMetricCell(metric: metric)
            }
        }
    }
}

struct FocusMetricItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let value: String
}

struct FocusMetricCell: View {
    let metric: FocusMetricItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(metric.title, systemImage: metric.icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(metric.value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

struct FocusActionButtonStyle: ButtonStyle {
    var namespace: Namespace.ID
    var colors: [Color]

    private var gradient: LinearGradient {
        LinearGradient(
            colors: colors.isEmpty ? [Color.green, Color.mint] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: (colors.last ?? .black).opacity(0.3), radius: 24, x: 0, y: 16)
                    .matchedGeometryEffect(id: "focusButtonBackground", in: namespace)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct FocusActionLabel: View {
    var title: String
    var subtitle: String
    var icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .contentTransition(.opacity)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FocusBreakHint: View {
    let state: StudyTrackingController.State
    let pausedDuration: TimeInterval
    let breakLogged: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
    }

    private var icon: String {
        switch state {
        case .paused:
            return breakLogged ? "cup.and.saucer.fill" : "pause.circle"
        case .running:
            return "figure.walk"
        case .idle, .finished:
            return "ticket"
        }
    }

    private var message: String {
        switch state {
        case .paused:
            if breakLogged {
                return "Break logged after 3 minutes • paused \(pausedDuration.formattedClock)"
            } else {
                return "Break logs at 03:00 • paused \(pausedDuration.formattedClock)"
            }
        case .running:
            return "Pause for 3+ minutes to automatically log a break."
        case .idle:
            return "Start the ticket and it will count up until you pause."
        case .finished:
            return "Session saved. Start another ticket when you're ready."
        }
    }
}

struct AmbientGlowBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.35),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.35)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .hueRotation(.degrees(animate ? 12 : -12))
            .animation(.easeInOut(duration: 23).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .scaleEffect(animate ? 1.2 : 0.8)
                .opacity(animate ? 0.15 : 0.08)
                .animation(.easeInOut(duration: 37).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.indigo.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .scaleEffect(animate ? 0.9 : 1.1)
                .opacity(animate ? 0.2 : 0.12)
                .animation(.easeInOut(duration: 43).repeatForever(autoreverses: true), value: animate)

            Color(.systemBackground)
                .opacity(0.35)
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    NavigationStack {
        StudyTrackingView()
    }
}
