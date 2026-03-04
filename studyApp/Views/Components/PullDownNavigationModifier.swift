//
//  PullDownNavigationModifier.swift
//  studyApp
//
//  A custom view modifier that enables pull-down gesture navigation.
//  Provides a clean, intuitive way to navigate to another view using a downward drag gesture.
//

import SwiftUI

/// A view modifier that adds pull-down gesture navigation capability
struct PullDownNavigationModifier: ViewModifier {

    // MARK: - State Properties

    @Binding var isNavigating: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    // MARK: - Constants

    /// Threshold distance to trigger navigation (in points)
    private let navigationThreshold: CGFloat = 150

    /// Maximum drag distance before resistance increases
    private let maxDragDistance: CGFloat = 250

    /// Visual indicator height
    private let indicatorHeight: CGFloat = 60

    // MARK: - Computed Properties

    /// Progress from 0.0 to 1.0 based on drag distance
    private var dragProgress: CGFloat {
        min(max(dragOffset / navigationThreshold, 0), 1)
    }

    /// Opacity for the visual indicator
    private var indicatorOpacity: Double {
        min(dragProgress * 1.5, 1.0)
    }

    /// Scale effect for the indicator
    private var indicatorScale: CGFloat {
        0.5 + (dragProgress * 0.5)
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .offset(y: isDragging ? min(dragOffset * 0.3, maxDragDistance * 0.3) : 0)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            handleDragChanged(value: value)
                        }
                        .onEnded { value in
                            handleDragEnded(value: value)
                        }
                )

            // Visual indicator at the top
            pullDownIndicator
                .opacity(indicatorOpacity)
                .scaleEffect(indicatorScale)
                .offset(y: isDragging ? min(dragOffset * 0.15, 40) : -50)
        }
    }

    // MARK: - Visual Components

    /// The visual indicator shown during pull-down gesture
    private var pullDownIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: dragProgress >= 1.0 ? "arrow.down.circle.fill" : "arrow.down.circle")
                .font(.system(size: 32))
                .foregroundStyle(
                    dragProgress >= 1.0
                        ? .white
                        : .white.opacity(0.7)
                )
                .symbolEffect(
                    .bounce,
                    options: .repeat(dragProgress >= 1.0 ? 1 : 0),
                    value: dragProgress >= 1.0
                )

            Text(dragProgress >= 1.0 ? "Release to enter focus" : "Pull down for focus mode")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
        .padding(.top, 50)
    }

    // MARK: - Gesture Handlers

    /// Handles drag gesture changes
    private func handleDragChanged(value: DragGesture.Value) {
        // Only track downward drags
        guard value.translation.height > 0 else {
            dragOffset = 0
            return
        }

        isDragging = true

        // Apply rubber-band effect for drags beyond threshold
        if value.translation.height > navigationThreshold {
            let excess = value.translation.height - navigationThreshold
            let resistance = log(excess / 50 + 1) * 50
            dragOffset = navigationThreshold + resistance
        } else {
            dragOffset = value.translation.height
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
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
            dragOffset = 0
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds pull-down gesture navigation to the view
    /// - Parameter isNavigating: Binding to control navigation state
    /// - Returns: Modified view with pull-down navigation capability
    func pullDownNavigation(isNavigating: Binding<Bool>) -> some View {
        modifier(PullDownNavigationModifier(isNavigating: isNavigating))
    }
}
