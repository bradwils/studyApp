//  WordsTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Words' tracking page. Transparent; the sentence and hairline slots stay empty.

import SwiftUI

struct WordsTrackingPage: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        let fade: Double = Double(1 - FocusLabMath.window(blend, 0, 0.5))
        VStack(alignment: .leading, spacing: 0) {
            header
                .frame(height: WordsLayout.headerHeight, alignment: .leading)
            Color.clear.frame(height: WordsLayout.sentenceSlot)
            VStack(alignment: .leading, spacing: 0) {
                facts
                buttons
                    .padding(.top, 28)
            }
            .opacity(fade)
            .allowsHitTesting(blend < 0.5)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WordsLayout.side)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if session.hasSession {
            Text(session.selectedSubject.code)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WordsPalette.dustgreen)
                .frame(minHeight: 44, alignment: .leading)
        } else {
            subjectMenu
        }
    }

    private var subjectMenu: some View {
        Menu {
            ForEach(session.subjects) { subject in
                Button(subject.name) { session.selectedSubject = subject }
            }
        } label: {
            HStack(spacing: 6) {
                Text(session.selectedSubject.code)
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(WordsPalette.dustgreen)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Facts

    private var facts: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let breakTotal: Int = session.breakCount + (session.isPaused ? 1 : 0)
            VStack(alignment: .leading, spacing: 0) {
                factRow("Today", WordsCopy.today(session.todayTotal(at: context.date)))
                factRow("Breaks", WordsCopy.breaks(count: breakTotal))
                factRow("With you", WordsCopy.names(session.friends.map { $0.name }))
            }
        }
        .padding(.top, 20)
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .foregroundStyle(WordsPalette.dustgreen)
                .frame(width: WordsLayout.labelWidth, alignment: .leading)
            Text(value)
                .foregroundStyle(WordsPalette.chalk)
        }
        .font(.system(size: 15, weight: .regular))
        .frame(maxWidth: .infinity, minHeight: WordsLayout.rowHeight, alignment: .leading)
    }

    // MARK: - Buttons

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var buttons: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.smooth(duration: 0.5)) { session.toggle() }
            } label: {
                WordsPrimaryLabel(title: primaryTitle)
            }
            .buttonStyle(WordsPressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.5)) { session.end() }
                } label: {
                    WordsSecondaryLabel(title: "End session")
                }
                .buttonStyle(WordsPressStyle())
            }
        }
    }
}
