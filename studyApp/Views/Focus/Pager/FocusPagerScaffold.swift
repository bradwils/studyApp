//  FocusPagerScaffold.swift
//  studyApp
//
//  Renders any FocusPagerScreen with FocusSessionScreen's structure. Back to front: the
//  full-bleed backdrop, the pinned timer and overlay (hit testing off), then FocusPager
//  drawn last so it receives every touch. Each page is a FocusPageScaffold: header band,
//  timer gap, then content. The backdrop and the pager run full width; page content and
//  the timer share one centred column.

import SwiftUI

/// A view that renders a focus screen as a pager over a pinned timer.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPagerScaffold<Screen: FocusPagerScreen>: View
/// ```
///
/// The caller owns `screenState`, as `FocusSessionScreen` always has, so it can read the lock
/// and the settled page. The scaffold keeps the state's page list in step with
/// `FocusPagePolicy.availablePages(for: screen.phase)`, unlocks when `screen.sessionID` changes,
/// and hides the tab bar while locked.
///
/// ```swift
/// @State private var screenState = FocusScreenState()
/// FocusPagerScaffold(screen: MyScreen(vm: vm), screenState: screenState)
/// ```
struct FocusPagerScaffold<Screen: FocusPagerScreen>: View {

    let screen: Screen
    let screenState: FocusScreenState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var standardTimerHeight: CGFloat = FocusPagerLayout.timerSlotBaseHeight

    // Both pages and the timer read this one value, so they can never disagree on where the timer is.
    private var slots: FocusPagerSlots {
        screen.slots(standard: FocusPagerSlots(
            headerHeight: FocusPagerLayout.headerSlotHeight,
            timerHeight: standardTimerHeight
        ))
    }

    var body: some View {
        FocusPagerStage { metrics in
            FocusPagerLayer { screen.backdrop(makeContext(metrics)) }
        } content: { metrics in
            let context = makeContext(metrics)
            ZStack {
                FocusPagerLayer { screen.timer(context) }
                    .frame(width: context.timerRect.width, height: context.timerRect.height)
                    .position(x: context.timerRect.midX, y: context.timerRect.midY)
                    .allowsHitTesting(false)

                FocusPagerLayer { screen.overlay(context) }
                    .frame(width: context.contentRect.width, height: context.contentRect.height, alignment: .top)
                    .position(x: context.contentRect.midX, y: context.contentRect.midY)
                    .allowsHitTesting(false)

                FocusPager(screenState: screenState) { page in
                    FocusPagerLayer {
                        FocusPageScaffold(slots: context.slots, horizontalPadding: screen.horizontalPadding(for: page)) {
                            screen.header(for: page, context)
                        } content: {
                            screen.content(for: page, context)
                        }
                    }
                    .frame(maxWidth: FocusPagerLayout.maxContentWidth)
                }
            }
        }
        .toolbar(screenState.isLocked ? .hidden : .visible, for: .tabBar)
        .onChange(of: FocusPagePolicy.availablePages(for: screen.phase), initial: true) { _, pages in
            var transaction = Transaction()
            if let scrolled = screenState.scrolledPage, !pages.contains(scrolled) {
                transaction.disablesAnimations = true
            }
            withTransaction(transaction) {
                screenState.reconcile(availablePages: pages)
            }
        }
        .onChange(of: screen.sessionID) {
            screenState.sessionIdentityDidChange()
        }
    }

    private func makeContext(_ metrics: FocusPagerStageMetrics) -> FocusPagerContext {
        FocusPagerContext(screenState: screenState, metrics: metrics, slots: slots, reduceMotion: reduceMotion)
    }
}

// Calls its content inside its own body, so a screen reading `position` through the context
// (blend, weights) redraws only this layer per scroll frame, never the scaffold or the pager.
private struct FocusPagerLayer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
