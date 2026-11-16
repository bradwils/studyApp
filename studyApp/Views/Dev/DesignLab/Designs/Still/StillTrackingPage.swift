//  StillTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Still's tracking page. Transparent; the timer row is left empty.

import SwiftUI

struct StillTrackingPage: View {

    let session: FocusLabSession
    let height: CGFloat
    let blend: CGFloat
    let spruce: Color

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            header
            lowerContent
        }
        .padding(.horizontal, StillLayout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            subjectPicker
            Spacer(minLength: 0)
        }
        .frame(height: StillLayout.headerHeight)
    }

    @ViewBuilder
    private var subjectPicker: some View {
        if session.hasSession {
            subjectCapsule(showsChevron: false)
        } else {
            Menu {
                ForEach(session.subjects) { subject in
                    Button(subject.name) { session.selectedSubject = subject }
                }
            } label: {
                subjectCapsule(showsChevron: true)
            }
        }
    }

    private func subjectCapsule(showsChevron: Bool) -> some View {
        HStack(spacing: 8) {
            Text(session.selectedSubject.code)
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(spruce)
            Text(session.selectedSubject.name)
                .font(.system(size: textSize))
                .foregroundStyle(.primary)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(minHeight: 44)
        .background(Capsule().fill(spruce.opacity(0.12)))
    }

    // MARK: - Below the header

    private var lowerContent: some View {
        let fade: Double = Double(1 - FocusLabMath.window(blend, 0, 0.5))
        let gap: CGFloat = max(StillLayout.trackingTimerY(height) - 55 - StillLayout.headerHeight, 0)
        return VStack(spacing: 0) {
            Color.clear.frame(height: gap)
            Color.clear.frame(height: StillLayout.trackingRow)
            Text(statusText)
                .font(.system(size: textSize))
                .foregroundStyle(.secondary)
            StillCapsuleButton(title: session.hasSession ? "Pause" : "Start session", spruce: spruce) {
                withAnimation(.smooth(duration: 0.45)) { session.toggle() }
            }
            .padding(.top, 20)
            Spacer(minLength: 16)
            StillLeaderboard(session: session, spruce: spruce)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .opacity(fade)
        .allowsHitTesting(blend < 0.5)
    }

    private var statusText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready when you are" }
            let mins: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(mins) min"
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        }
    }
}

// MARK: - Leaderboard

private struct StillBoardRow: Identifiable {

    let name: String
    let code: String
    let minutes: Int
    let isYou: Bool

    var id: String { name }
}

private struct StillLeaderboard: View {

    let session: FocusLabSession
    let spruce: Color

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            board(at: context.date)
        }
    }

    private func board(at date: Date) -> some View {
        let rows: [StillBoardRow] = makeRows(at: date)
        let orderKey: String = rows.map { $0.name }.joined(separator: ",")
        return VStack(alignment: .leading, spacing: 0) {
            Text("Studying now")
                .font(.system(size: textSize))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            ForEach(rows) { row in
                rowView(row)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.5), value: orderKey)
    }

    private func makeRows(at date: Date) -> [StillBoardRow] {
        var result: [StillBoardRow] = session.friends.map { friend in
            StillBoardRow(name: friend.name, code: friend.subjectCode, minutes: friend.minutes, isYou: false)
        }
        if session.hasSession {
            let mine: Int = Int(session.studyElapsed(at: date) / 60)
            result.append(StillBoardRow(name: "You", code: session.selectedSubject.code, minutes: mine, isYou: true))
        }
        return result.sorted { $0.minutes > $1.minutes }
    }

    private func rowView(_ row: StillBoardRow) -> some View {
        let nameColor: Color = row.isYou ? spruce : Color.primary
        let nameWeight: Font.Weight = row.isYou ? .semibold : .medium
        return HStack(spacing: 0) {
            Text(row.name)
                .font(.system(size: textSize, weight: nameWeight))
                .foregroundStyle(nameColor)
                .frame(width: 64, alignment: .leading)
            Text(row.code)
                .font(.system(size: textSize))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text("\(row.minutes) min")
                .font(.system(size: textSize))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(height: 40)
    }
}
