//
//  PureFocusViewModel.swift
//  studyApp
//
//  Created by brad wils on 2/1/26.
//

import SwiftUI
import Combine

class PureFocusViewModel: ObservableObject {
    
    // @Published marks this property so SwiftUI automatically
    // updates any Views observing this model when it changes
    @Published var showDragger: Bool = true
    
    // Called whenever the sheet's detent changes
    // This demonstrates one-way flow: View notifies Model of changes
    // Model updates its @Published property, which triggers View updates
    func updateDraggerVisibility(for detent: PresentationDetent) {
        // Show dragger only when sheet is at smallest size (0.1)
        // PresentationDetent.fraction(0.1) checks if the detent equals that specific value
        showDragger = detent == PresentationDetent.fraction(0.1)
    }
}
