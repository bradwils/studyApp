//  TicketKit.swift
//  studyApp
//
//  DEV ONLY — Ticket's palette, type, buttons and the one layout struct that owns every
//  number the paper layer, the pinned layer and both pages share.

import SwiftUI

enum TicketPalette {
    static let periwinkle = Color(labHex: 0xC9D2F5)
    static let navy = Color(labHex: 0x1A1F4B)
    static let paper = Color(labHex: 0xFFFDF8)
    static let cherry = Color(labHex: 0xE23D5B)
    static let mauve = Color(labHex: 0x6C7299)
    static let cool = Color(labHex: 0xD9D9E3)
    static let dim = Color(labHex: 0xF1EEF0)

    static func background(isPaused: Bool, blend: CGFloat) -> Color {
        let base: Color = isPaused ? cool : periwinkle
        return base.labBlend(navy, blend)
    }
}

enum TicketFont {
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Futura-Bold", size: size, relativeTo: .body)
    }

    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Futura-Medium", size: size, relativeTo: .body)
    }
}

struct TicketLayout {

    static let headerHeight: CGFloat = 52
    static let trackingSideInset: CGFloat = 24
    static let trackingTop: CGFloat = 68
    static let trackingHeight: CGFloat = 300
    static let trackingPerforationY: CGFloat = 208
    static let trackingStubHeight: CGFloat = 92
    static let focusSideInset: CGFloat = 12
    static let focusTop: CGFloat = 8
    static let focusStubHeight: CGFloat = 216
    static let notchDiameter: CGFloat = 22
    static let perforationInset: CGFloat = 18
    static let punchCount: Int = 10
    static let punchDiameter: CGFloat = 12
    static let punchSideInset: CGFloat = 30
    static let punchLift: CGFloat = 22
    static let captionDrop: CGFloat = 46

    let ticket: CGRect
    let cornerRadius: CGFloat
    let perforationY: CGFloat
    let timerCenter: CGPoint
    let timerScale: CGFloat
    let focusPerforationY: CGFloat

    init(size: CGSize, blend: CGFloat) {
        let eased: CGFloat = FocusLabMath.smoothstep(blend)
        let trackingWidth: CGFloat = size.width - 2 * TicketLayout.trackingSideInset
        let focusWidth: CGFloat = size.width - 2 * TicketLayout.focusSideInset
        let focusHeight: CGFloat = max(size.height - 20, TicketLayout.focusStubHeight + 120)
        let tracking = CGRect(
            x: TicketLayout.trackingSideInset,
            y: TicketLayout.trackingTop,
            width: trackingWidth,
            height: TicketLayout.trackingHeight
        )
        let focus = CGRect(
            x: TicketLayout.focusSideInset,
            y: TicketLayout.focusTop,
            width: focusWidth,
            height: focusHeight
        )
        let shown = CGRect(
            x: FocusLabMath.lerp(tracking.minX, focus.minX, eased),
            y: FocusLabMath.lerp(tracking.minY, focus.minY, eased),
            width: FocusLabMath.lerp(tracking.width, focus.width, eased),
            height: FocusLabMath.lerp(tracking.height, focus.height, eased)
        )
        let focusPerforation: CGFloat = focusHeight - TicketLayout.focusStubHeight
        let shownPerforation: CGFloat = FocusLabMath.lerp(TicketLayout.trackingPerforationY, focusPerforation, eased)
        let timerY: CGFloat = shown.minY + shownPerforation / 2

        ticket = shown
        cornerRadius = FocusLabMath.lerp(22, 30, eased)
        perforationY = shownPerforation
        timerCenter = CGPoint(x: shown.midX, y: timerY)
        timerScale = FocusLabMath.lerp(1, 1.18, eased)
        focusPerforationY = focusPerforation
    }
}

struct TicketPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TicketPrimaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TicketFont.medium(16))
                .foregroundStyle(TicketPalette.paper)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(TicketPalette.navy, in: Capsule())
        }
        .buttonStyle(TicketPressStyle())
    }
}

struct TicketSecondaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TicketFont.medium(16))
                .foregroundStyle(TicketPalette.navy)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(TicketPalette.paper, in: Capsule())
        }
        .buttonStyle(TicketPressStyle())
    }
}
