//
//  CustomBottomSheet.swift
//  studyApp
//
//  Created by brad wils on 10/1/26.
//

import SwiftUI

struct CustomBottomSheet: View {
    
    @State var predictedEndLocation: CGFloat = 0
    
    @State var newHeight: CGFloat = 0

    @State private var height: CGFloat = 120
    
    @State var translation: CGFloat = 0 //diff between starting point & current point
    
    @State var newH: CGFloat = 0;
    
    @State var oldH: CGFloat = 0;
    
    
    var body: some View {
        GeometryReader { geo in
//            let fullyExpanded = geo.size.height * 0.85
////            let semiExpanded = geo.size.height * 0.35
//            let collapsed = geo.size.height * 0.2
            // Capture geometry info needed inside gesture closures
            let containerHeight = geo.size.height
            
            let maxContainerHeight: CGFloat = 120;
            
            let containerMinY = geo.frame(in: .global).minY //does not ignore safe area
            

            // Inline gesture so we can convert predicted/global coordinates to local
            let gesture = DragGesture()
                    
                .onChanged { value in
                    
                    //need to do grabLocation - oldH = offset, then add that to newH
//                    offset = value.location.y - (containerHeight - oldH)
                    //add offset to newH
                    //be done
                    
                    
                    
                    translation = value.translation.height
                    newH = oldH - translation
//                    let clamped = min(max(newH, collapsed), fullyExpanded)
                    // Convert predicted global Y into local container coordinates
                    let predictedGlobalY = value.predictedEndLocation.y
                    let predictedLocalY = predictedGlobalY - containerMinY
                    // Keep an observable of the predicted local position for debugging/UI
                    predictedEndLocation = min(max(predictedLocalY, 0), containerHeight)
                    height = newH
                }
                .onEnded { value in
                    // Convert predicted and current end points to local container coordinates
                    let predictedGlobalY = value.predictedEndLocation.y 
                    let predictedLocalY = predictedGlobalY - containerMinY
                    let currentLocalY = value.location.y - containerMinY

                    // Difference between predicted and actual end positions
                    let diff = predictedLocalY - currentLocalY
                    translation = diff // COULD BE CAUSING ISSUES?

                    // If predicted motion is significant (>40pt) use predicted position, otherwise use actual
                    var targetLocalY: CGFloat = oldH //default to old height if in doubt
                    
                    if (abs(diff) > 40) {
                        var overmmentumAdjustedLocalY: CGFloat = 0;
                        if (predictedLocalY > currentLocalY) { //ADJUST FOR OVERMOMENTUM TO BOTTOM OF SCREEN (SCREENMAX)
                            overmmentumAdjustedLocalY = predictedLocalY - diff * 0.5 //adjust for momentum
                            targetLocalY = min(overmmentumAdjustedLocalY, containerHeight - 120) //minimum height of 120
                        } else { //adjust for overmomentum to top of scren (screenmin)
                            overmmentumAdjustedLocalY = predictedLocalY + diff * 0.5 //adjust for momentum
                            targetLocalY = max(overmmentumAdjustedLocalY, maxContainerHeight) //minimum height of 0 for now
                        }
                        
                        
                        
                    } else {
                        targetLocalY = currentLocalY
                    }
                    //if so,

                    // Convert local Y (distance from top) into sheet height (distance from bottom)
                    var targetHeight = containerHeight - targetLocalY
                    // Clamp into allowed range

                    withAnimation(.interactiveSpring()) { //tweak this spring, make it custom!
                        height = targetHeight
                    }
                    oldH = height

                }

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 16) {
                        Text("predictedEndLocation: \(predictedEndLocation)")
                        Text("viewHeight: \(geo.size.height)")
                        Text("translation: \(translation)")
                        Text("newH: \(newH)")
                        Text("oldH: \(oldH)")
                        ForEach(0..<40) { i in
                            Text("Item \(i)")
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
            .frame(width: geo.size.width)
            .frame(height: height, alignment: .bottom)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray)
                    .shadow(radius: 10)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .gesture(gesture)
//            .animation(.interactiveSpring(), value: height)
            .onAppear {
                height = 120
                oldH = 120
            }
        }
    }
}
