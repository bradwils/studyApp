//  WordsKit.swift
//  studyApp
//
//  DEV ONLY — palette, geometry, copy and small shared pieces for the Words design.

import SwiftUI

enum WordsPalette {
    static let board = Color(labHex: 0x1E3B33)
    static let deepboard = Color(labHex: 0x12261F)
    static let aubergine = Color(labHex: 0x3A2540)
    static let chalk = Color(labHex: 0xF4F1DE)
    static let lemon = Color(labHex: 0xE9E27A)
    static let dustgreen = Color(labHex: 0x9DB5A6)
}

enum WordsLayout {
    static let side: CGFloat = 28
    static let headerHeight: CGFloat = 56
    static let sentenceGap: CGFloat = 48
    static let sentenceHeight: CGFloat = 200
    static let hairlineGap: CGFloat = 14
    static let hairlineHeight: CGFloat = 2
    static let hairlineRow: CGFloat = 30
    static let labelWidth: CGFloat = 84
    static let rowHeight: CGFloat = 30

    static var sentenceTop: CGFloat { headerHeight + sentenceGap }
    static var sentenceSlot: CGFloat { sentenceGap + sentenceHeight + hairlineRow }
}

struct WordsPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct WordsPrimaryLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(WordsPalette.board)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
            .background(WordsPalette.lemon, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WordsSecondaryLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .regular))
            .underline()
            .foregroundStyle(WordsPalette.chalk)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

struct WordsSentence {
    let lead: String
    let number: String
    let tail: String

    var full: String { lead + number + tail }
}

struct WordsCopy {

    static func tracking(session: FocusLabSession, at date: Date) -> WordsSentence {
        if session.isPaused { return onBreak(session: session, at: date) }
        let subject: String = session.selectedSubject.name
        if session.isRunning {
            let minutes: Int = Int(session.studyElapsed(at: date) / 60)
            return running(minutes: minutes, subject: subject)
        }
        return idle(length: session.lastCompletedLength, subject: subject)
    }

    static func focus(session: FocusLabSession, at date: Date) -> WordsSentence {
        if session.isPaused { return onBreak(session: session, at: date) }
        guard session.hasFocusBlock, let remaining = session.focusRemaining(at: date) else {
            return plain("No focus block yet.")
        }
        if session.isFocusComplete(at: date) { return plain("That block is done.") }
        let left: Int = Int((remaining / 60).rounded(.up))
        return WordsSentence(lead: "", number: capitalised(minutesText(left)), tail: " left.")
    }

    static func today(_ interval: TimeInterval) -> String {
        let total: Int = Int(interval / 60)
        let hours: Int = total / 60
        let minutes: Int = total % 60
        if hours == 0 { return minutesText(minutes) }
        let hoursPart: String = spell(hours) + (hours == 1 ? " hour" : " hours")
        if minutes == 0 { return hoursPart }
        return hoursPart + " " + spell(minutes)
    }

    static func breaks(count: Int) -> String {
        count == 0 ? "none" : spell(count)
    }

    static func names(_ names: [String]) -> String {
        guard let last = names.last else { return "no one yet" }
        if names.count == 1 { return last }
        let head: String = names.dropLast().joined(separator: ", ")
        return head + " and " + last
    }

    // MARK: - Pieces

    private static func idle(length: TimeInterval?, subject: String) -> WordsSentence {
        guard let length else { return plain("Ready for \(subject).") }
        let minutes: Int = Int(length / 60)
        return WordsSentence(lead: "Saved ", number: minutesText(minutes), tail: " of \(subject).")
    }

    private static func running(minutes: Int, subject: String) -> WordsSentence {
        if minutes == 0 { return plain("Just started on \(subject).") }
        let tail: String = " of \(subject)."
        if minutes < 60 {
            return WordsSentence(lead: "", number: capitalised(minutesText(minutes)), tail: tail)
        }
        let hours: Int = minutes / 60
        let rest: Int = minutes % 60
        var words: String = spell(hours) + (hours == 1 ? " hour" : " hours")
        if rest > 0 { words += " and " + minutesText(rest) }
        return WordsSentence(lead: "", number: capitalised(words), tail: tail)
    }

    private static func onBreak(session: FocusLabSession, at date: Date) -> WordsSentence {
        let minutes: Int = Int(session.currentBreakElapsed(at: date) / 60)
        if minutes == 0 { return plain("On a break.") }
        return WordsSentence(lead: "On a break for ", number: minutesText(minutes), tail: ".")
    }

    private static func plain(_ text: String) -> WordsSentence {
        WordsSentence(lead: "", number: "", tail: text)
    }

    private static func minutesText(_ minutes: Int) -> String {
        spell(minutes) + (minutes == 1 ? " minute" : " minutes")
    }

    private static func capitalised(_ text: String) -> String {
        text.prefix(1).uppercased() + String(text.dropFirst())
    }

    private static func spell(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}
