//
//  CustomBottomSheet.swift
//  studyApp
//
//  Created by brad wils on 10/1/26.
//

import SwiftUI

/// A customizable bottom sheet component with drag gesture support and momentum-based animations.
/// The sheet can be dragged to resize and will animate smoothly when released based on gesture velocity.
/// 
/// As the sheet expands, it smoothly transitions from a floating rounded card appearance
/// to a full-width edge-to-edge sheet, similar to the system SwiftUI sheet behavior.
struct CustomBottomSheet: View {
    
    // MARK: - Constants
    
    /// Minimum height the sheet can collapse to
    private let minimumHeight: CGFloat = 120
    
    /// Threshold for considering a drag gesture as having significant momentum
    private let momentumThreshold: CGFloat = 10
    
    /// Momentum dampening factor (lower = more dampening)
    private let momentumDampening: CGFloat = 0.1
    
    // MARK: - Layout Constants (Progress-Driven)
    
    /// Horizontal inset when sheet is collapsed (floating card appearance)
    private let collapsedHorizontalInset: CGFloat = 16
    
    /// Horizontal inset when sheet is fully expanded (edge-to-edge)
    private let expandedHorizontalInset: CGFloat = 0
    
    
    /// Corner radius when sheet is collapsed
    private let collapsedCornerRadius: CGFloat = 40
    
    /// Corner radius when sheet is fully expanded
    private let expandedCornerRadius: CGFloat = 20
    
    /// Bottom padding when collapsed (floating above safe area)
    private let collapsedBottomPadding: CGFloat = 12
    
    /// Bottom padding when expanded (extends into safe area)
    private let expandedBottomPadding: CGFloat = 0

    // MARK: - State Properties
    
    /// Current height of the bottom sheet
    @State private var sheetHeight: CGFloat = 120
    
    /// Height of the sheet before the current gesture began
    @State private var previousHeight: CGFloat = 120
    
    /// Offset from the initial touch point to the sheet edge
    @State private var touchOffset: CGFloat = 0
    
    /// Whether a drag gesture is currently active
    @State private var isDragging = false
        
    // MARK: - Detent Configuration
    // Detents are "snap points" where the sheet prefers to rest
    // These are defined as RATIOS (0.0 to 1.0) of the container height
    // Example: 0.1 = 10% of screen height, 0.7 = 70% of screen height
    
    /// Detent snap points as ratios of container height
    /// - 0.1 = Small peek (10% of screen)
    /// - 0.3 = Medium size (30% of screen)  
    /// - 0.7 = Large/expanded (70% of screen)
    /// These ratios represent the SHEET HEIGHT, not Y position from top
    private let detentRatios: [CGFloat] = [0.1, 0.3, 0.7]
    
    /// Converts detent ratios to absolute pixel heights for the current container
    /// Example: If container is 800pt tall and ratio is 0.3, returns 240pt
    /// - Parameter containerHeight: The total height of the container in points
    /// - Returns: Array of absolute sheet heights in points
    private func detentHeights(for containerHeight: CGFloat) -> [CGFloat] {
        return detentRatios.map { ratio in
            ratio * containerHeight  // Convert 0.0-1.0 ratio to actual pixel height
        }
    }
    
    // MARK: - Progress Calculation
    
    /// Calculates a normalized progress value (0.0 to 1.0) representing how expanded the sheet is.
    /// - 0.0 = collapsed at minimum detent
    /// - 1.0 = fully expanded at maximum detent
    /// - Values can exceed 0-1 during over-drag, but layout interpolation is clamped
    /// - Parameter containerHeight: The total height of the container
    /// - Returns: Progress value where 0 = collapsed, 1 = expanded
    private func expansionProgress(for containerHeight: CGFloat) -> CGFloat {
        let detents = detentHeights(for: containerHeight)
        guard let minDetent = detents.first, let maxDetent = detents.last, maxDetent > minDetent else {
            return 0
        }
        
        // Calculate progress: how far between min and max detent
        let progress = (sheetHeight - minDetent) / (maxDetent - minDetent)
        return progress
    }
    
    /// Interpolates between two values based on progress (clamped to 0-1)
    /// - Parameters:
    ///   - from: Value at progress 0 (collapsed)
    ///   - to: Value at progress 1 (expanded)
    ///   - progress: Current expansion progress
    /// - Returns: Interpolated value
    private func interpolate(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 1)
        return from + (to - from) * clampedProgress
    }







    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let containerWidth = geometry.size.width
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            // Calculate the single progress value driving all layout interpolations
            let progress = expansionProgress(for: containerHeight)
            
            // Progress-driven layout values
            let horizontalInset = interpolate(
                from: collapsedHorizontalInset,
                to: expandedHorizontalInset,
                progress: progress
            )

            let bottomPadding = interpolate(
                from: collapsedBottomPadding,
                to: expandedBottomPadding,
                progress: progress
            )
            
            // Width interpolates from inset width to full width
            let sheetWidth = containerWidth - (horizontalInset * 2)
            
            // When expanded, extend into safe area; when collapsed, stay above it
            let safeAreaExtension = interpolate(
                from: 0,
                to: safeAreaBottom,
                progress: progress
            )
            
            // Total visible height includes safe area extension when expanded
            let visibleSheetHeight = sheetHeight + safeAreaExtension
            
            let containerMinY = geometry.frame(in: .global).minY
            
            ZStack(alignment: .bottom) {
                // Sheet container with progress-driven styling
                sheetContent
                    

                    .frame(width: sheetWidth)
                    .frame(height: visibleSheetHeight, alignment: .top)
                    .background(
                        ContainerRelativeShape()
                            .glassEffect()
//                            .fill(Color(hex: "#7b3bff"))
                    )
                
                    .clipShape(
                        ContainerRelativeShape()
//                        .fill(Color.gray)
                        
//                            topLeadingRadius: cornerRadius,
//                            bottomLeadingRadius: interpolate(from: cornerRadius, to: 0, progress: progress),
//                            bottomTrailingRadius: interpolate(from: cornerRadius, to: 0, progress: progress),
//                    topTrailingRadius: cornerRadius,
//                            style: .continuous
                    )
                    
                    .padding(.bottom, bottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .gesture(
                createDragGesture(
                    containerHeight: containerHeight,
                    containerMinY: containerMinY
                )
            )
            .onAppear {
                sheetHeight = minimumHeight
                previousHeight = minimumHeight
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - View Components
    
    /// The main content of the bottom sheet
    private var sheetContent: some View {
        VStack(spacing: 0) {
            dragIndicator
            


            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<40) { index in
                        Text("Item \(index)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding()
        }
        .ignoresSafeArea(edges: .bottom)
    }
    












    /// The capsule-shaped drag indicator at the top of the sheet
    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary)
            .frame(width: 40, height: 6)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
    
    /// Background styling for the sheet with dynamic corner radius
    /// - Parameter cornerRadius: The corner radius based on expansion progress
    private func sheetBackground(cornerRadius: CGFloat) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            bottomLeadingRadius: cornerRadius,
            bottomTrailingRadius: cornerRadius,
            topTrailingRadius: cornerRadius
        )
        .fill(Color.gray)
        .shadow(radius: 10)
    }
    
    // MARK: - Gesture Handling
    
    /// Creates the drag gesture for resizing the sheet
    /// - Parameters:
    ///   - containerHeight: Total height of the container
    ///   - containerMinY: The minimum Y position of the container in global coordinates
    /// - Returns: A configured DragGesture
    private func createDragGesture(containerHeight: CGFloat, containerMinY: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(
                    value: value,
                    containerHeight: containerHeight,
                    containerMinY: containerMinY
                )
            }
            .onEnded { value in
                handleDragEnded(
                    value: value,
                    containerHeight: containerHeight,
                    containerMinY: containerMinY
                )
            }
    }
    
    /// Handles updates during an active drag gesture
    private func handleDragChanged(
        value: DragGesture.Value,
        containerHeight: CGFloat,
        containerMinY: CGFloat
    ) {
        // Calculate touch offset on first drag event
        if !isDragging {
            touchOffset = value.location.y - (containerHeight - previousHeight)
            isDragging = true
        }
        
        // Calculate new height based on drag translation
        let translationHeight = value.translation.height
        let calculatedHeight = previousHeight - translationHeight
        
        sheetHeight = calculatedHeight - touchOffset


    }
    
    /// Handles the end of a drag gesture, applying momentum-based positioning and snapping to detents
    /// 
    /// SNAPPING LOGIC:
    /// 1. If gesture has momentum (fast swipe), predict where it would land
    /// 2. Find the nearest detent to that predicted position
    /// 3. Animate to that detent
    /// 4. If no momentum (slow release), just snap to nearest detent if out of bounds
    private func handleDragEnded(
        value: DragGesture.Value,
        containerHeight: CGFloat,
        containerMinY: CGFloat
    ) {
        isDragging = false
        
        // STEP 1: Convert detent ratios (0.1, 0.3, 0.7) to absolute heights
        // Example: container=800pt → detents=[80pt, 240pt, 560pt]
        let detentSnapPoints = detentHeights(for: containerHeight)
        
        // STEP 2: Calculate gesture momentum
        // We work in Y coordinates (from top of container)
        // predictedLocalY = where iOS thinks the finger would end up based on velocity
        // currentLocalY = where the finger actually is right now
        let predictedEndY = value.predictedEndLocation.y - containerMinY  // Predicted Y position
        let currentY = value.location.y - containerMinY                   // Current Y position
        let momentum = predictedEndY - currentY                           // How much momentum (positive = downward)
        
        // Start with current sheet height, we'll calculate the target snap point
        var targetSheetHeight = sheetHeight
        
        // STEP 3: Decide snapping behavior based on momentum
        if abs(momentum) > momentumThreshold {
            // === MOMENTUM PATH: Fast swipe detected ===
            print("Fast swipe detected (momentum: \(momentum))")
            
            // Calculate where the sheet should end up based on momentum
            // This dampens the momentum so it doesn't fly to extreme positions
            let predictedSheetTopY = calculateMomentumAdjustedPosition(
                predictedLocalY: predictedEndY,
                currentLocalY: currentY,
                momentumDifference: momentum,
                containerHeight: containerHeight
            )
            print("→ Momentum predicts sheet top at Y: \(predictedSheetTopY)")
            
            // COORDINATE CONVERSION: Y position → Sheet height
            // If sheet top is at Y=200 in a 800pt container, sheet height = 800 - 200 = 600pt
            let predictedSheetHeight = containerHeight - predictedSheetTopY
            print("→ Which means sheet height: \(predictedSheetHeight)")
            
            // Snap to nearest detent
            // Example: if predicted height is 520pt and detents are [80, 240, 560],
            // it will snap to 560pt (closest match)
            targetSheetHeight = findNearestDetent(
                for: predictedSheetHeight,
                detents: detentSnapPoints,
                minHeight: minimumHeight,
                maxHeight: containerHeight
            )
            print("→ Snapping to nearest detent: \(targetSheetHeight)pt")

            // Animate to the target detent
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                sheetHeight = targetSheetHeight
            }

        } else {
            // === STATIONARY PATH: Slow drag/no momentum ===
            print("Slow release, checking bounds...")
            
            // Only snap if the sheet is outside the valid detent range
            // Example: detents=[80, 240, 560], if sheet is at 50pt (below 80), snap to 80
            
            if sheetHeight < detentSnapPoints[0] {
                // Sheet is too small (below minimum detent)
                // Snap UP to minimum detent
                print("→ Below minimum detent, snapping to \(detentSnapPoints[0])pt")
                targetSheetHeight = detentSnapPoints[0]
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                    sheetHeight = targetSheetHeight
                }
                
            } else if sheetHeight > detentSnapPoints[detentSnapPoints.count - 1] {
                // Sheet is too large (above maximum detent)
                // Snap DOWN to maximum detent
                print("→ Above maximum detent, snapping to \(detentSnapPoints.last!)pt")
                targetSheetHeight = detentSnapPoints[detentSnapPoints.count - 1]
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                    sheetHeight = targetSheetHeight
                }
                
            } else {
                // Sheet is within valid range [min, max], no snapping needed
                // User can leave it at any height between detents
                print("→ Within bounds, staying at \(sheetHeight)pt")
                targetSheetHeight = sheetHeight
            }
        }
        
        // Store the final sheet height for next gesture
        previousHeight = sheetHeight
    }
    
    // MARK: - Helper Methods
    
    /// Calculates where the sheet should end up based on gesture momentum
    ///
    /// COORDINATE SYSTEM EXPLANATION:
    /// - We work in Y coordinates measured from TOP of container
    /// - Y=0 is the TOP of the screen
    /// - Y=containerHeight is the BOTTOM of the screen
    /// - The sheet's TOP edge position is what we calculate here
    /// - Sheet height = containerHeight - sheetTopY
    ///
    /// MOMENTUM DAMPENING:
    /// - iOS predicts where gesture would end (predictedLocalY)
    /// - We dampen that by `momentumDampening` factor (default 0.1 = 10%)
    /// - This prevents the sheet from flying to extreme positions
    ///
    /// - Parameters:
    ///   - predictedLocalY: Where iOS predicts the finger would end (Y from top)
    ///   - currentLocalY: Where the finger currently is (Y from top)
    ///   - momentumDifference: predicted - current (positive = downward motion)
    ///   - containerHeight: Total height of the container in points
    /// - Returns: The adjusted Y position for the sheet's TOP edge
    private func calculateMomentumAdjustedPosition(
        predictedLocalY: CGFloat,
        currentLocalY: CGFloat,
        momentumDifference: CGFloat,
        containerHeight: CGFloat
    ) -> CGFloat {
        let dampenedPrediction: CGFloat
        let clampedSheetTopY: CGFloat
        
        if predictedLocalY > currentLocalY {
            // === DRAGGING DOWNWARD (increasing Y) ===
            // Sheet is collapsing/shrinking
            // Dampen the momentum: reduce how far down it goes
            dampenedPrediction = predictedLocalY - (momentumDifference * momentumDampening)
            
            // Clamp: don't let sheet top go below minimum sheet height
            // If containerHeight=800 and minimumHeight=120, max Y for sheet top is 680
            let maxAllowedY = containerHeight - minimumHeight
            clampedSheetTopY = min(dampenedPrediction, maxAllowedY)
            
            print("  ↓ Downward swipe: predicted Y=\(predictedLocalY) → dampened=\(dampenedPrediction) → clamped=\(clampedSheetTopY)")
            
        } else {
            // === DRAGGING UPWARD (decreasing Y) ===
            // Sheet is expanding/growing
            // Dampen the momentum: reduce how far up it goes
            // Note: momentumDifference is negative here, so we ADD it
            dampenedPrediction = predictedLocalY + (momentumDifference * momentumDampening)
            
            // Clamp: don't let sheet top go above 0 (top of screen)
            clampedSheetTopY = max(dampenedPrediction, 0)
            
            print("  ↑ Upward swipe: predicted Y=\(predictedLocalY) → dampened=\(dampenedPrediction) → clamped=\(clampedSheetTopY)")
        }
        
        return clampedSheetTopY
    }
    
    
    /// Finds the nearest detent snap point to a target height
    ///
    /// SNAPPING ALGORITHM:
    /// - Compares target height against all detent heights
    /// - Finds the one with smallest absolute difference
    /// - Example: target=500pt, detents=[80, 240, 560]
    ///   → distances: |80-500|=420, |240-500|=260, |560-500|=60
    ///   → nearest is 560pt (smallest distance)
    ///
    /// - Parameters:
    ///   - targetHeight: The sheet height we want to snap from (in points)
    ///   - detents: Array of valid detent snap points (absolute heights in points)
    ///   - minHeight: Minimum allowed sheet height (safety clamp)
    ///   - maxHeight: Maximum allowed sheet height (safety clamp)
    /// - Returns: The nearest detent height, clamped to [minHeight, maxHeight]
    private func findNearestDetent(
        for targetHeight: CGFloat, 
        detents: [CGFloat], 
        minHeight: CGFloat, 
        maxHeight: CGFloat
    ) -> CGFloat {
        // Find detent with smallest absolute distance to target
        let nearestDetent = detents.min(by: { detentA, detentB in
            let distanceA = abs(detentA - targetHeight)
            let distanceB = abs(detentB - targetHeight)
            return distanceA < distanceB
        }) ?? targetHeight  // Fallback to target if no detents exist
        
        // Safety clamp to ensure result is within valid bounds
        // This prevents edge cases where detents might be misconfigured
        let clampedDetent = min(max(nearestDetent, minHeight), maxHeight)
        
        return clampedDetent
    }
}


#Preview {
    PureFocusView()
}
