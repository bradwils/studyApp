//  WordsPinned.swift
//  studyApp
//
//  DEV ONLY — Words' fixed layer: the sentence and the minute hairline, drawn above the pager.

import SwiftUI

struct WordsPinned: View {

    let session: FocusLabSession
    let blend: CGFloat
    let animates: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: WordsLayout.sentenceTop)
            sentences
            Color.clear.frame(height: WordsLayout.hairlineGap)
            WordsHairline(session: session, blend: blend, animates: animates)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WordsLayout.side)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private var sentences: some View {
        TimelineView(.periodic(from: .now, by: 5)) { context in
            let trackingText: WordsSentence = WordsCopy.tracking(session: session, at: context.date)
            let focusText: WordsSentence = WordsCopy.focus(session: session, at: context.date)
            let key: String = trackingText.full + "|" + focusText.full
            let trackingOpacity: Double = Double(1 - blend)
            let focusOpacity: Double = Double(blend)
            ZStack(alignment: .topLeading) {
                WordsSentenceView(sentence: trackingText)
                    .id(trackingText.full)
                    .transition(.opacity)
                    .opacity(trackingOpacity)
                WordsSentenceView(sentence: focusText)
                    .id(focusText.full)
                    .transition(.opacity)
                    .opacity(focusOpacity)
            }
            .animation(.smooth(duration: 0.6), value: key)
        }
        .frame(height: WordsLayout.sentenceHeight, alignment: .topLeading)
    }
}

private struct WordsSentenceView: View {

    let sentence: WordsSentence

    private let plain: Font = Font.custom("Baskerville", size: 40, relativeTo: .largeTitle)
    private let italic: Font = Font.custom("Baskerville-SemiBoldItalic", size: 40, relativeTo: .largeTitle)

    var body: some View {
        let joined: Text = Text(sentence.lead).font(plain)
            + Text(sentence.number).font(italic)
            + Text(sentence.tail).font(plain)
        return joined
            .foregroundStyle(WordsPalette.chalk)
            .lineSpacing(4)
            .lineLimit(4)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WordsHairline: View {

    let session: FocusLabSession
    let blend: CGFloat
    let animates: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let minute: Double = minuteFraction(at: context.date)
            let focus: Double = session.focusProgress(at: context.date) ?? minute
            WordsHairlineBar(minute: minute, focus: focus, blend: blend, animates: animates)
        }
        .frame(height: WordsLayout.hairlineHeight)
        .accessibilityHidden(true)
    }

    private func minuteFraction(at date: Date) -> Double {
        guard session.hasSession else { return 0 }
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        return elapsed.truncatingRemainder(dividingBy: 60) / 60
    }
}

private struct WordsHairlineBar: View {

    let minute: Double
    let focus: Double
    let blend: CGFloat
    let animates: Bool

    var body: some View {
        GeometryReader { proxy in
            let full: CGFloat = proxy.size.width
            let shown: CGFloat = FocusLabMath.lerp(CGFloat(minute), CGFloat(focus), blend)
            let barWidth: CGFloat = full * FocusLabMath.clamp(shown)
            let sweep: Animation? = animates ? Animation.linear(duration: 1) : nil
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(WordsPalette.chalk.opacity(0.12))
                Rectangle()
                    .fill(WordsPalette.lemon)
                    .frame(width: barWidth)
                    .animation(sweep, value: minute + focus)
            }
        }
    }
}
