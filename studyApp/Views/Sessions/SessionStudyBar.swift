import SwiftUI
import Charts

// Breaks have no span, so they show as the bare track between bars.
struct SessionStudyBar: View {
    let spans: [StudySpan]
    let range: ClosedRange<Date>
    var isCompact = false

    var body: some View {
        Chart(Array(spans.enumerated()), id: \.offset) { _, span in
            BarMark(
                xStart: .value("Start", span.start),
                xEnd: .value("End", span.end),
                y: .value("Session", "")
            )
            .foregroundStyle(by: .value("Kind", span.kind.title))
        }
        .chartForegroundStyleScale(
            domain: StudyTimeKind.allCases.map(\.title),
            range: StudyTimeKind.allCases.map(\.color)
        )
        .chartXScale(domain: range)
        .chartXAxis(isCompact ? .hidden : .automatic)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.background(.gray.opacity(0.2))
                .clipShape(.rect(cornerRadius: isCompact ? 2 : 4))
        }
        .frame(height: isCompact ? 6 : 44)
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        StudyTimeline.totals(spans)
            .sorted { $0.value > $1.value }
            .map { "\($0.key.title) \(Duration.seconds($0.value).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide)))" }
            .joined(separator: ", ")
    }
}

extension StudyTimeKind {
    var title: String {
        switch self {
        case .study: "Study"
        case .focusEndedEarly: "Focus, ended early"
        case .focusCompleted: "Focus"
        }
    }

    var color: Color {
        switch self {
        case .study: .green
        case .focusEndedEarly: .blue
        case .focusCompleted: .purple
        }
    }
}

#Preview {
    let start = Date.now.addingTimeInterval(-3600)
    func at(_ minutes: Double) -> Date { start.addingTimeInterval(minutes * 60) }
    let spans = [
        StudySpan(kind: .study, start: at(0), end: at(5)),
        StudySpan(kind: .focusEndedEarly, start: at(5), end: at(15)),
        StudySpan(kind: .focusCompleted, start: at(20), end: at(45)),
        StudySpan(kind: .study, start: at(45), end: at(60))
    ]
    return VStack(spacing: 24) {
        SessionStudyBar(spans: spans, range: at(0)...at(60))
        SessionStudyBar(spans: spans, range: at(0)...at(60), isCompact: true)
    }
    .padding()
}
