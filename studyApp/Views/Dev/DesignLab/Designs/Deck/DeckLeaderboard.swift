//  DeckLeaderboard.swift
//  studyApp
//
//  DEV ONLY — Deck's leaderboard sheet: rounded top corners, a grabber that lifts the
//  sheet over the timer panel, and a friends list that re-sorts as "You" climbs.

import SwiftUI

struct DeckLeaderboardSheet: View {

    let session: FocusLabSession
    let layout: DeckLayout
    @Binding var isOpen: Bool

    @ScaledMetric(relativeTo: .subheadline) private var headingSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            handle
            DeckBoard(session: session)
        }
        .frame(width: layout.sheetWidth, height: DeckLayout.sheetContentHeight, alignment: .top)
        .background(alignment: .top) {
            sheetFill
        }
    }

    private var sheetFill: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: DeckLayout.sheetRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: DeckLayout.sheetRadius,
            style: .continuous
        )
        .fill(DeckPalette.petal)
        .frame(width: layout.sheetWidth, height: layout.sheetFillHeight)
    }

    private var handle: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isOpen.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Capsule()
                    .fill(DeckPalette.mulberry.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                Text("Studying now")
                    .font(.system(size: headingSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(DeckPalette.wine)
            }
            .padding(.top, 8)
            .padding(.bottom, 6)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle leaderboard")
    }
}

private struct DeckBoardRow: Identifiable {

    let rank: Int
    let name: String
    let code: String
    let minutes: Int
    let isYou: Bool

    var id: String { name }
}

private struct DeckBoard: View {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .subheadline) private var bodySize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 13

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            board(at: context.date)
        }
    }

    private func board(at date: Date) -> some View {
        let rows: [DeckBoardRow] = makeRows(at: date)
        let orderKey: String = rows.map { $0.name }.joined(separator: ",")
        return VStack(spacing: 0) {
            ForEach(rows) { row in
                rowView(row)
            }
        }
        .padding(.horizontal, 8)
        .animation(.smooth(duration: 0.5), value: orderKey)
    }

    private func makeRows(at date: Date) -> [DeckBoardRow] {
        var unranked: [DeckBoardRow] = session.friends.map { friend in
            DeckBoardRow(rank: 0, name: friend.name, code: friend.subjectCode, minutes: friend.minutes, isYou: false)
        }
        if session.hasSession {
            let mine: Int = Int(session.studyElapsed(at: date) / 60)
            unranked.append(DeckBoardRow(rank: 0, name: "You", code: session.selectedSubject.code, minutes: mine, isYou: true))
        }
        let sorted: [DeckBoardRow] = unranked.sorted { $0.minutes > $1.minutes }
        var ranked: [DeckBoardRow] = []
        for (index, row) in sorted.enumerated() {
            ranked.append(DeckBoardRow(rank: index + 1, name: row.name, code: row.code, minutes: row.minutes, isYou: row.isYou))
        }
        return ranked
    }

    private func rowView(_ row: DeckBoardRow) -> some View {
        let nameWeight: Font.Weight = row.isYou ? .semibold : .medium
        let highlight: Color = row.isYou ? DeckPalette.lime.opacity(0.35) : Color.clear
        return HStack(spacing: 0) {
            Text("\(row.rank)")
                .font(.system(size: bodySize))
                .foregroundStyle(DeckPalette.mulberry)
                .frame(width: 22, alignment: .leading)
            Text(row.name)
                .font(.system(size: bodySize, weight: nameWeight))
                .foregroundStyle(DeckPalette.wine)
                .frame(width: 64, alignment: .leading)
            Text(row.code)
                .font(.system(size: captionSize))
                .foregroundStyle(DeckPalette.mulberry)
            Spacer(minLength: 8)
            Text("\(row.minutes) min")
                .font(.system(size: bodySize))
                .monospacedDigit()
                .foregroundStyle(DeckPalette.wine)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(highlight))
    }
}
