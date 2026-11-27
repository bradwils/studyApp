import Foundation

enum StudyTimeKind: CaseIterable {
    case study
    case focusEndedEarly
    case focusCompleted
}

struct StudySpan: Equatable {
    let kind: StudyTimeKind
    let start: Date
    let end: Date

    var duration: TimeInterval { end.timeIntervalSince(start) }
}

struct FocusWindow: Equatable {
    let interval: DateInterval
    let target: TimeInterval
}

// Breaks are the gaps between spans. A completed block counts as completed focus only up
// to its target: the countdown stops at zero, so time after it is ordinary study.
enum StudyTimeline {
    static func spans(for session: StudySession, now: Date) -> [StudySpan] {
        let study = (session.sections ?? []).compactMap { interval($0.startedAt, $0.endedAt ?? now) }
        let focus = session.focusBlocks.compactMap { block in
            interval(block.startedAt, block.endedAt ?? now).map { FocusWindow(interval: $0, target: block.targetDuration) }
        }
        return spans(study: study, focus: focus)
    }

    static func spans(study: [DateInterval], focus: [FocusWindow]) -> [StudySpan] {
        let study = study.sorted { $0.start < $1.start }
        let focus = focus.sorted { $0.interval.start < $1.interval.start }
        let completed = focus.map { window in
            study.reduce(0) { $0 + overlap($1, window.interval) } >= window.target
        }
        var consumed = Array(repeating: TimeInterval(0), count: focus.count)
        var result: [StudySpan] = []

        for section in study {
            let cuts = focus.flatMap { [$0.interval.start, $0.interval.end] }
                .filter { $0 > section.start && $0 < section.end }
            let bounds = ([section.start] + cuts.sorted() + [section.end])
            for (start, end) in zip(bounds, bounds.dropFirst()) where end > start {
                let middle = start.addingTimeInterval(end.timeIntervalSince(start) / 2)
                guard let index = focus.firstIndex(where: { $0.interval.contains(middle) }) else {
                    append(StudySpan(kind: .study, start: start, end: end), to: &result)
                    continue
                }
                guard completed[index] else {
                    append(StudySpan(kind: .focusEndedEarly, start: start, end: end), to: &result)
                    continue
                }
                let focusedEnd = min(end, start.addingTimeInterval(max(0, focus[index].target - consumed[index])))
                consumed[index] += end.timeIntervalSince(start)
                if focusedEnd > start {
                    append(StudySpan(kind: .focusCompleted, start: start, end: focusedEnd), to: &result)
                }
                if end > focusedEnd {
                    append(StudySpan(kind: .study, start: focusedEnd, end: end), to: &result)
                }
            }
        }
        return result
    }

    static func totals(_ spans: [StudySpan]) -> [StudyTimeKind: TimeInterval] {
        spans.reduce(into: [:]) { $0[$1.kind, default: 0] += $1.duration }
    }

    private static func interval(_ start: Date, _ end: Date) -> DateInterval? {
        end >= start ? DateInterval(start: start, end: end) : nil
    }

    private static func overlap(_ lhs: DateInterval, _ rhs: DateInterval) -> TimeInterval {
        lhs.intersection(with: rhs)?.duration ?? 0
    }

    // Joins touching spans of one kind so a block boundary inside plain study doesn't show as a seam.
    private static func append(_ span: StudySpan, to spans: inout [StudySpan]) {
        if let last = spans.last, last.kind == span.kind, last.end == span.start {
            spans[spans.count - 1] = StudySpan(kind: span.kind, start: last.start, end: span.end)
        } else {
            spans.append(span)
        }
    }
}
