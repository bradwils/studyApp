//
//  ViewportBorder.swift
//  studyApp
//
//  Created by brad wils on 08/01/26.
//

import SwiftUI

/// A reusable Shape for creating viewport borders with dynamic corner radius
struct ViewportBorder: Shape {
    let strokeWidth: CGFloat
    let cornerPercent: CGFloat // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        // Step 1: Inset the rectangle so the line width doesn't get cut off at the edges
        let insetRect = rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)
        
        // Step 2: Calculate dynamic corner radius based on viewport size
        let radius = insetRect.width * cornerPercent
        
        var path = Path()
        // Step 3: Use the optimized addRoundedRect for smooth "squircle" corners
        path.addRoundedRect(
            in: insetRect,
            cornerSize: CGSize(width: radius, height: radius),
            style: .continuous
        )
        return path
    }
}
