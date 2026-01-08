import SwiftUI
import Combine

/// A lightweight goal timer that can be started mid-session to keep a short, named objective on track.
///
/// The timer draws along the outer edges of its container, beginning at the bottom center and easing
/// up either side until it reaches the top center. This makes it easy for new SwiftUI users to
/// associate elapsed time with visible progress without needing UIKit overlays or custom layers.
struct FocusGoalTimer: View {
    /// Fixed goal duration in seconds.
    private let duration: TimeInterval = 10
    
    @State private var goalName: String = ""
    @State private var isRunning: Bool = false
    @State private var startDate: Date?
    @State private var progress: CGFloat = 0
    @State private var remainingTime: TimeInterval = 10
    
    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            TextField("Name (optional)", text: $goalName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
            
            timerCanvas
            
            Button(action: toggleTimer) {
                HStack(spacing: 8) {
                    Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.headline)
                    Text(isRunning ? "Stop goal" : "Start 10s goal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .onReceive(ticker) { date in
            guard isRunning, let startDate else { return }
            
            let elapsed = min(date.timeIntervalSince(startDate), duration)
            let updatedProgress = CGFloat(elapsed / duration)
            
            progress = updatedProgress
            remainingTime = max(duration - elapsed, 0)
            
            if elapsed >= duration {
                isRunning = false
                startDate = nil
                progress = 1
                remainingTime = 0
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus goal timer")
                    .font(.subheadline.weight(.semibold))
                Text("Start a quick loop without leaving your session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(timeString(for: remainingTime))
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                )
        }
        .padding(.horizontal, 12)
    }
    
    /// Draws the wrap-around path and overlays the goal label in the center.
    private var timerCanvas: some View {
        ZStack {
            ScreenWrapShape()
                .stroke(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .padding(10)
            
            ScreenWrapShape()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.9), Color.blue.opacity(0.9)],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color.pink.opacity(0.25), radius: 8, x: 0, y: 6)
                .padding(10)
            
            VStack(spacing: 6) {
                Text(goalName.isEmpty ? "Quick focus goal" : goalName)
                    .font(.headline)
                    .lineLimit(1)
                Text(timeString(for: remainingTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 240)
    }
    
    private func startTimer() {
        startDate = Date()
        remainingTime = duration
        progress = 0
        isRunning = true
    }
    
    private func toggleTimer() {
        if isRunning {
            isRunning = false
            startDate = nil
        } else {
            startTimer()
        }
    }
    
    private func timeString(for interval: TimeInterval) -> String {
        let clamped = max(interval, 0)
        return String(format: "00:%02d", Int(ceil(clamped)))
    }
}

/// Builds a path that hugs the container edges, starting at the bottom center and finishing at the top center.
private struct ScreenWrapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview {
    FocusGoalTimer()
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.35), Color.blue.opacity(0.3), Color.purple.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
