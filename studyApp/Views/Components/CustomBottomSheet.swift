//
//  CustomBottomSheet.swift
//  studyApp
//
//  Created by brad wils on 10/1/26.
//

import SwiftUI

/// A customizable bottom sheet component with drag gesture support and momentum-based animations.
/// The sheet can be dragged to resize and will animate smoothly when released based on gesture velocity.
struct CustomBottomSheet: View {
    
    // MARK: - Constants
    
    /// Minimum height the sheet can collapse to
    private let minimumHeight: CGFloat = 120
    
    /// Threshold for considering a drag gesture as having significant momentum
    private let momentumThreshold: CGFloat = 40
    
    /// Momentum dampening factor (lower = more dampening)
    private let momentumDampening: CGFloat = 0.1
    
    let customDetents: [CGFloat] = [0.1, 0.4, 0.8]
    
    // MARK: - State Properties
    
    /// Current height of the bottom sheet
    @State private var sheetHeight: CGFloat = 120
    
    /// Height of the sheet before the current gesture began
    @State private var previousHeight: CGFloat = 120
    
    /// Offset from the initial touch point to the sheet edge
    @State private var touchOffset: CGFloat = 0
    
    /// Whether a drag gesture is currently active
    @State private var isDragging = false
    
    /// Measured height of the container provided by GeometryReader
    @State private var containerHeight: CGFloat = 0
    
    @State var adjustedDetentSizes: [CGFloat] = []  //to be calculated whenever geometryReader changes
    
    
    //    @State private var customDetents: [CGFloat] = [] //need to be computed, will be done
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height  //refactor to containerHeight, as it only ignores the bottom safe zone still.3e
            //based on containerHeight, assert detents which are mapped against predictions
            
            sheetContent
                .background(sheetBackground)
                .ignoresSafeArea(edges: .bottom)
                .gesture(
                    createDragGesture(
                        containerHeight: containerHeight,
                        containerMinY: containerMinY
                    )
                )
                .onAppear {
                    sheetHeight = minimumHeight
                    previousHeight = minimumHeight
                    updateContainerMetrics(newHeight: containerHeight)
                }
                .onChange(of: containerHeight) { new in  //where the changed value of geometryHeight is newHeight
                    updateContainerMetrics(newHeight: new)
                }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - View Components
    
    /// The main content of the bottom sheet
    private var sheetContent: some View {
        VStack(spacing: 0) {
            dragIndicator
            
            debugContent
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<40) { index in
                        Text("Item \(index)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding()
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var debugContent: some View {
        VStack {
            ForEach(adjustedDetentSizes.indices, id: \.self) { index in
                Text("Detent: \(Int(adjustedDetentSizes[index]))")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
    }
    
    /// The capsule-shaped drag indicator at the top of the sheet
    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary)
            .frame(width: 40, height: 6)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
    
    /// Background styling for the sheet
    private var sheetBackground: some View {
        RoundedRectangle(cornerRadius: 24)
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
        
        //update clamped value - todoq
    }
    
    /// Handles the end of a drag gesture, applying momentum-based positioning
    private func handleDragEnded(
        value: DragGesture.Value,
        containerHeight: CGFloat,
        containerMinY: CGFloat
    ) {
        isDragging = false
        
        // Convert coordinates to local container space
        let predictedLocalY = value.predictedEndLocation.y - containerMinY
        let currentLocalY = value.location.y - containerMinY
        let momentumDifference = predictedLocalY - currentLocalY
        
        var snappedHeight: CGFloat = 0
        
        var targetLocalY = previousHeight
        
        if abs(momentumDifference) > momentumThreshold {  // Apply momentum-based positioning if gesture has significant velocity)
            targetLocalY = calculateMomentumAdjustedPosition(
                predictedLocalY: predictedLocalY,
                currentLocalY: currentLocalY,
                momentumDifference: momentumDifference,
                containerHeight: containerHeight
            )
            
            // Snap to the nearest detent
            let targetHeight = containerHeight - targetLocalY
            snappedHeight = findNearestDetent(
                for: targetHeight, detents: adjustedDetentSizes, minHeight: minimumHeight,
                maxHeight: containerHeight)
            
            targetLocalY = containerHeight - snappedHeight
            
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                sheetHeight = snappedHeight
            }
            
        } else {
            // Stationary release - use current position
            //check it's not out of bounds, if so move to nearest detent
            
            if sheetHeight < adjustedDetentSizes[0] {
                snappedHeight = adjustedDetentSizes[0]  //make it snap to lowest detent
            } else if sheetHeight > adjustedDetentSizes[adjustedDetentSizes.count - 1] {
                //make it snap to highest detent
                snappedHeight = adjustedDetentSizes[adjustedDetentSizes.count - 1]
            }
            
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                sheetHeight = snappedHeight
                print(sheetHeight)
            }
            targetLocalY = sheetHeight  //saves the localY for reference on next drag
        }
        
        previousHeight = containerHeight - targetLocalY
        
        //MARK: see below, this was the given code. have a look.
        // let rawHeight = containerHeight - targetLocalY
        // let resolvedHeight = resolveDetent(for: rawHeight, containerHeight: containerHeight)
        
        // previousHeight = resolvedHeight
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the final position with momentum dampening applied
    /// - Parameters:
    ///   - predictedLocalY: The predicted end position based on gesture velocity
    ///   - currentLocalY: The current touch position in local coordinates
    ///   - momentumDifference: The difference between predicted and current positions
    ///   - containerHeight: Total height of the container
    /// - Returns: The adjusted target Y position
    private func calculateMomentumAdjustedPosition(
        predictedLocalY: CGFloat,
        currentLocalY: CGFloat,
        momentumDifference: CGFloat,
        containerHeight: CGFloat
    ) -> CGFloat {
        let adjustedPrediction: CGFloat
        let clampedPosition: CGFloat
        
        if predictedLocalY > currentLocalY {
            // Dragging downward - dampen momentum and clamp to minimum sheet height
            adjustedPrediction = predictedLocalY - momentumDifference * momentumDampening
            clampedPosition = min(adjustedPrediction, containerHeight - minimumHeight)
        } else {
            // Dragging upward - dampen momentum and clamp to top of container
            adjustedPrediction = predictedLocalY + momentumDifference * momentumDampening
            clampedPosition = max(adjustedPrediction, 0)
        }
        
        return clampedPosition
    }
    
    private func updateContainerMetrics(newHeight: CGFloat) {
        // Update detents based on new container height
        adjustedDetentSizes = customDetents.map { $0 * newHeight }
    }
    
    /// Finds the nearest detent height to the target height, clamped within min and max bounds.
    /// - Parameters:
    ///   - targetHeight: The desired height to snap to.
    ///   - detents: Array of available detent heights.
    ///   - minHeight: Minimum allowed height.
    ///   - maxHeight: Maximum allowed height.
    /// - Returns: The snapped height closest to the target.
    private func findNearestDetent(
        for targetHeight: CGFloat, detents: [CGFloat], minHeight: CGFloat, maxHeight: CGFloat
    ) -> CGFloat {
        // Find the detent with the smallest absolute difference to the target height
        let nearestDetent =
        detents.min(by: { abs($0 - targetHeight) < abs($1 - targetHeight) }) ?? targetHeight
        // Clamp the result to ensure it's within valid bounds
        return min(max(nearestDetent, minHeight), maxHeight)
    }
    
}
