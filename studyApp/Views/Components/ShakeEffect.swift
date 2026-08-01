//
//  ShakeEffect.swift
//  studyApp
//
//  Created by brad wils on 28/7/26.

import SwiftUI

/// Horizontal shake, driven by `animatableData` — bump the value (e.g. `trigger += 1`)
/// inside `withAnimation` to replay the shake.
struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 6
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
