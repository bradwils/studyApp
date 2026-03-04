//
//  SwipeUpFocusTab.swift
//  studyApp
//
//  A persistent tab at the bottom that indicates and enables swipe-up navigation to focus mode.
//  Provides clear visual affordance and intuitive gesture-based navigation.
//

import SwiftUI

/// A swipeable tab component that sits at the bottom of the screen
/// and reveals focus mode when swiped up
struct SwipeUpFocusTab: View {

    // MARK: - Bindings

    @Binding var isNavigating: Bool

    // MARK: - State Properties

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var showHint: Bool = true

    // MARK: - Constants

    /// Height of the tab when collapsed
    private let collapsedHeight: CGFloat = 80

    /// Threshold to trigger navigation
    private let navigationThreshold: CGFloat = 200

    /// Maximum drag distance
    private let maxDragDistance: CGFloat = 300

    // MARK: - Computed Properties

    /// Progress from 0.0 to 1.0 based on drag distance
    private var swipeProgress: CGFloat {
        min(max(dragOffset / navigationThreshold, 0), 1)
    }

    /// Background opacity increases as you swipe
    private var backgroundOpacity: Double {
        0.15 + (Double(swipeProgress) * 0.15)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // The swipeable tab
            tabContent
                .offset(y: -dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            handleDragChanged(value: value)
                        }
                        .onEnded { value in
                            handleDragEnded(value: value)
                        }
                )
        }
        .onAppear {
            // Show hint animation for first few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHint = false
                }
            }
        }
    }

    // MARK: - Components

    /// The main tab content
    private var tabContent: some View {
        VStack(spacing: 12) {
            // Drag handle
            dragHandle

            // Main content area
            VStack(spacing: 8) {
                // Icon that animates based on progress
                Image(systemName: swipeProgress >= 1.0 ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .symbolEffect(
                        .bounce,
                        options: .repeat(swipeProgress >= 1.0 ? 1 : 0),
                        value: swipeProgress >= 1.0
                    )
                    .symbolEffect(
                        .pulse.byLayer,
                        options: .repeat(.periodic(delay: 2)),
                        value: showHint
                    )

                // Text label
                Text(swipeProgress >= 1.0 ? "Release to focus" : "Swipe up for focus mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Subtle hint text
                if !isDragging && showHint {
                    Text("Try swiping up")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .opacity(backgroundOpacity)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(
            color: .black.opacity(isDragging ? 0.3 : 0.15),
            radius: isDragging ? 20 : 10,
            y: isDragging ? -5 : -2
        )
    }

    /// The drag handle indicator at the top of the tab
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(.white.opacity(0.5))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .scaleEffect(x: isDragging ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }

    // MARK: - Gesture Handlers

    /// Handles drag gesture changes
    private func handleDragChanged(value: DragGesture.Value) {
        // Only track upward drags (negative translation)
        guard value.translation.height < 0 else {
            dragOffset = 0
            return
        }

        isDragging = true
        showHint = false

        let translation = abs(value.translation.height)

        // Apply rubber-band effect for drags beyond threshold
        if translation > navigationThreshold {
            let excess = translation - navigationThreshold
            let resistance = log(excess / 50 + 1) * 50
            dragOffset = navigationThreshold + resistance
        } else {
            dragOffset = translation
        }
    }

    /// Handles drag gesture end
    private func handleDragEnded(value: DragGesture.Value) {
        isDragging = false

        // Check if we've crossed the threshold
        if dragOffset >= navigationThreshold {
            // Trigger navigation
            withAnimation(.easeOut(duration: 0.3)) {
                isNavigating = true
            }
        }

        // Reset drag offset with animation
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75)) {
            dragOffset = 0
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.pink, .purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SwipeUpFocusTab(isNavigating: .constant(false))
    }
}
