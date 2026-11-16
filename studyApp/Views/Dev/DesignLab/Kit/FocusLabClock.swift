//  FocusLabClock.swift
//  studyApp
//
//  DEV ONLY — ticking clock text for Focus Design Lab screens.

import SwiftUI

/// Ticks once a second and inherits whatever font and colour the design applies to it.
struct FocusLabClock: View {

    let session: FocusLabSession
    var source: FocusLabSession.ClockSource = .automatic
    var idleText: String = "00:00"

    /// Set this for typefaces without tabular figures (Didot, Futura, Avenir…): every
    /// digit gets a cell this wide, so the clock doesn't shuffle sideways as it ticks.
    var digitWidth: CGFloat?

    var body: some View {
        TimelineView(.periodic(from: session.tickOrigin(for: source), by: 1)) { context in
            let whole = wholeSeconds(at: context.date)
            let text = whole.map { formattedElapsed(TimeInterval($0)) } ?? idleText

            Group {
                if let digitWidth {
                    FocusLabDigits(text: text, digitWidth: digitWidth)
                } else {
                    Text(text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .animation(.smooth(duration: 0.3), value: whole)
        }
    }

    // A countdown rounds up so a 25 minute block opens on 25:00, not 24:59.
    private func wholeSeconds(at date: Date) -> Int? {
        guard let seconds = session.seconds(for: source, at: date) else { return nil }
        let countsDown = source == .focusRemaining || (source == .automatic && session.hasFocusBlock && !session.isPaused)
        return Int(countsDown ? seconds.rounded(.up) : seconds.rounded(.down))
    }
}

/// Lays text out one character per fixed-width cell.
struct FocusLabDigits: View {

    let text: String
    var digitWidth: CGFloat
    /// Width for ":" and other non-digits. Defaults to half a digit.
    var separatorWidth: CGFloat?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { item in
                Text(String(item.element))
                    .contentTransition(.numericText())
                    .frame(width: item.element.isNumber ? digitWidth : (separatorWidth ?? digitWidth * 0.5))
            }
        }
    }
}
