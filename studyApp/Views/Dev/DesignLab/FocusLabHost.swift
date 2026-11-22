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
    // Owned here, as FocusSessionScreen owns its own, so the lab bar can hide while locked.
    @State private var screenState = FocusScreenState()
    @State private var chrome = FocusLabChrome()

    init(design: FocusLabDesign) {
        _design = State(initialValue: design)
    }

    var body: some View {
        design.screen(session: session, screenState: screenState)
            .id(design)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !screenState.isLocked {
                    labBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.35), value: screenState.isLocked)
            .environment(chrome)
            .preferredColorScheme(chrome.scheme ?? design.colorScheme)
    }

    // MARK: - Lab bar

    // A fixed dark capsule rather than glass, so it reads the same over every design's bottom edge.
    private var labBar: some View {
        HStack(spacing: 4) {
            barButton("xmark", label: "Close") { dismiss() }

            barButton("chevron.left", label: "Previous design") { step(-1) }

            VStack(spacing: 1) {
                Text(design.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(position + 1) of \(FocusLabDesign.allCases.count)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity)

            barButton("chevron.right", label: "Next design") { step(1) }

            sessionMenu
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .foregroundStyle(.white)
        .tint(.white)
        .background(Color.black.opacity(0.62), in: Capsule())
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
        chrome.scheme = nil
        // The new design's pager opens on tracking, so its state has to start there too.
        screenState = FocusScreenState()
        design = all[next]
    }
}

#Preview {
    FocusLabHost(design: .margin)
}
