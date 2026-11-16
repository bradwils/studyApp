//  FocusLabHost.swift
//  studyApp
//
//  DEV ONLY — full-screen host for a Focus Design Lab screen. Owns the mock session,
//  so stepping between designs keeps the same session running underneath them, and
//  draws the lab bar in the space the real tab bar would occupy.

import SwiftUI

struct FocusLabHost: View {

    @Environment(\.dismiss) private var dismiss

    @State private var design: FocusLabDesign
    @State private var session = FocusLabSession()

    init(design: FocusLabDesign) {
        _design = State(initialValue: design)
    }

    var body: some View {
        design.screen(session: session)
            .id(design)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !session.isLocked {
                    labBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.35), value: session.isLocked)
            .preferredColorScheme(design.colorScheme)
    }

    // MARK: - Lab bar

    private var labBar: some View {
        HStack(spacing: 4) {
            barButton("xmark", label: "Close") { dismiss() }

            barButton("chevron.left", label: "Previous design") { step(-1) }

            VStack(spacing: 1) {
                Text(design.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(position + 1) of \(FocusLabDesign.allCases.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity)

            barButton("chevron.right", label: "Next design") { step(1) }

            sessionMenu
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .glassEffect()
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var sessionMenu: some View {
        Menu {
            Button("Skip ahead 5 minutes", systemImage: "forward") {
                session.skip(5 * 60)
            }
            Button("Skip ahead 20 minutes", systemImage: "forward.end") {
                session.skip(20 * 60)
            }
            Button("Load a 47 minute session", systemImage: "clock.arrow.circlepath") {
                session.loadSampleSession()
            }
            Button("Reset", systemImage: "arrow.counterclockwise", role: .destructive) {
                session.reset()
            }
        } label: {
            Image(systemName: "clock.badge.questionmark")
                .font(.body.weight(.medium))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Session time controls")
    }

    private func barButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.medium))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    private var position: Int {
        FocusLabDesign.allCases.firstIndex(of: design) ?? 0
    }

    private func step(_ direction: Int) {
        let all = FocusLabDesign.allCases
        let next = (position + direction + all.count) % all.count
        design = all[next]
    }
}

#Preview {
    FocusLabHost(design: .reference)
}
