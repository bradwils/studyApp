//  StillBreakScreen.swift
//  studyApp
//
//  DEV ONLY — Still's break screen: a full-bleed amber place you leave only with Resume.

import SwiftUI

struct StillBreakScreen: View {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 34
    @ScaledMetric(relativeTo: .largeTitle) private var clockSize: CGFloat = 76
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17
    @ScaledMetric(relativeTo: .subheadline) private var noteSize: CGFloat = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading
            clock
            Spacer(minLength: 16)
            resumeButton
            endButton
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { StillPalette.amber.ignoresSafeArea() }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("On a break")
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(StillPalette.umber)
            Text("\(session.selectedSubject.name) is waiting")
                .font(.system(size: bodySize))
                .foregroundStyle(StillPalette.umber.opacity(0.7))
        }
        .padding(.top, 72)
    }

    private var clock: some View {
        VStack(alignment: .leading, spacing: 8) {
            FocusLabClock(session: session, source: .rest, idleText: "00:00")
                .font(.system(size: clockSize, weight: .bold))
                .foregroundStyle(StillPalette.umber)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("You studied \(StillFormat.minutes(session.studyElapsed())) before this break")
                .font(.system(size: noteSize))
                .foregroundStyle(StillPalette.umber.opacity(0.7))
        }
        .padding(.top, 36)
    }

    private var resumeButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.45)) { session.resume() }
        } label: {
            Text("Resume")
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundStyle(StillPalette.amber)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(StillPalette.umber)
                )
        }
        .buttonStyle(StillPressStyle())
    }

    private var endButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.45)) { session.end() }
        } label: {
            Text("End session")
                .font(.system(size: bodySize))
                .underline()
                .foregroundStyle(StillPalette.umber)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(StillPressStyle())
        .padding(.bottom, 20)
    }
}
