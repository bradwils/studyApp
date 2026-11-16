//  DeckMusicStrip.swift
//  studyApp
//
//  DEV ONLY — Deck's now-playing strip. Purely cosmetic: the play button only flips a
//  glyph, and the lime line keeps moving along the screen width either way.

import SwiftUI

struct DeckMusicStrip: View {

    let layout: DeckLayout

    @State private var isPlaying = true

    @ScaledMetric(relativeTo: .subheadline) private var titleSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) private var artistSize: CGFloat = 13

    var body: some View {
        ZStack(alignment: .topLeading) {
            DeckPlaybackLine(width: layout.size.width, isPlaying: isPlaying)
                .offset(y: DeckLayout.stripLineY)
            card
                .padding(.horizontal, DeckLayout.sideInset)
                .padding(.top, DeckLayout.stripTop)
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DeckPalette.mulberry.opacity(0.25))
                .frame(width: 40, height: 40)
            titles
            Spacer(minLength: 8)
            playButton
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(height: DeckLayout.stripHeight)
        .background(
            RoundedRectangle(cornerRadius: DeckLayout.stripRadius, style: .continuous)
                .fill(DeckPalette.petal)
        )
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Lo-fi focus mix")
                .font(.system(size: titleSize, weight: .semibold))
                .foregroundStyle(DeckPalette.wine)
                .lineLimit(1)
            Text("Chillhop Essentials")
                .font(.system(size: artistSize))
                .foregroundStyle(DeckPalette.mulberry)
                .lineLimit(1)
        }
    }

    private var playButton: some View {
        Button {
            isPlaying.toggle()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 18))
                .foregroundStyle(DeckPalette.wine)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DeckPressStyle())
        .accessibilityLabel(isPlaying ? "Pause music" : "Play music")
    }
}

private struct DeckPlaybackLine: View {

    let width: CGFloat
    let isPlaying: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            line(at: context.date)
        }
    }

    private func line(at date: Date) -> some View {
        let seconds: Double = date.timeIntervalSinceReferenceDate
        let fraction: Double = seconds.truncatingRemainder(dividingBy: 210) / 210
        let lineWidth: CGFloat = width * CGFloat(fraction)
        let animated: Bool = !reduceMotion && fraction > 0.01
        let animation: Animation? = animated ? Animation.linear(duration: 1) : nil
        let opacity: Double = isPlaying ? 1 : 0.35
        return Rectangle()
            .fill(DeckPalette.lime)
            .frame(width: lineWidth, height: 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(opacity)
            .animation(animation, value: fraction)
    }
}
