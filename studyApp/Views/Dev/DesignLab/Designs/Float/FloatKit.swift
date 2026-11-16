//  FloatKit.swift
//  studyApp
//
//  DEV ONLY — palette, layout constants and the colour field of the Float design.

import SwiftUI

struct FloatColorSet {
    let tone: Color
    let accent: Color
    let light: Color
}

enum FloatPalette {
    static let ink = Color(labHex: 0x14233A)
    static let white = Color(labHex: 0xFFFFFF)
    static let depth = Color(labHex: 0x0E1F33)

    static func trackingSet(_ index: Int) -> FloatColorSet {
        switch index % 4 {
        case 1:
            return FloatColorSet(tone: Color(labHex: 0xFFB79A), accent: Color(labHex: 0xFF8FB1), light: Color(labHex: 0xFFF1D6))
        case 2:
            return FloatColorSet(tone: Color(labHex: 0x9BE089), accent: Color(labHex: 0x4FC7B0), light: Color(labHex: 0xF3FBD2))
        case 3:
            return FloatColorSet(tone: Color(labHex: 0xB79CFF), accent: Color(labHex: 0x7FB6FF), light: Color(labHex: 0xF6E9FF))
        default:
            return FloatColorSet(tone: Color(labHex: 0x7FD6E8), accent: Color(labHex: 0x8FA8FF), light: Color(labHex: 0xE6FBF4))
        }
    }

    static func shownSet(_ index: Int, blend: CGFloat) -> FloatColorSet {
        let base: FloatColorSet = trackingSet(index)
        let deepen: CGFloat = 0.62
        let focusTone: Color = base.tone.labBlend(depth, deepen)
        let focusAccent: Color = base.accent.labBlend(depth, deepen)
        let focusLight: Color = base.light.labBlend(depth, deepen)
        return FloatColorSet(
            tone: base.tone.labBlend(focusTone, blend),
            accent: base.accent.labBlend(focusAccent, blend),
            light: base.light.labBlend(focusLight, blend)
        )
    }
}

enum FloatLayout {
    static let headerHeight: CGFloat = 56
    static let slotGap: CGFloat = 20
    static let slotHeight: CGFloat = 252
    static let sideInset: CGFloat = 20
}

enum FloatFormat {
    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(interval / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        guard hours > 0 else { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}

struct FloatBackdrop: View {

    let subjectIndex: Int
    let blend: CGFloat
    let reduceMotion: Bool

    var body: some View {
        let set: FloatColorSet = FloatPalette.shownSet(subjectIndex, blend: blend)
        if reduceMotion {
            FloatMesh(set: set, seconds: 0, subjectIndex: subjectIndex)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                let seconds: Double = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                FloatMesh(set: set, seconds: seconds, subjectIndex: subjectIndex)
            }
        }
    }
}

private struct FloatMesh: View {

    let set: FloatColorSet
    let seconds: Double
    let subjectIndex: Int

    var body: some View {
        let colorA: Color = set.tone
        let colorB: Color = set.accent
        let colorC: Color = set.light
        let midX: Float = Float(0.5 + 0.14 * sin(seconds * 0.21))
        let midY: Float = Float(0.5 + 0.11 * cos(seconds * 0.17))
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                SIMD2<Float>(0, 0.5), SIMD2<Float>(midX, midY), SIMD2<Float>(1, 0.5),
                SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
            ],
            colors: [
                colorC, colorA, colorC,
                colorA, colorB, colorA,
                colorB, colorA, colorC
            ]
        )
        .animation(.smooth(duration: 0.8), value: subjectIndex)
    }
}
