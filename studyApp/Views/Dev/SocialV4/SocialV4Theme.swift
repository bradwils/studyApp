import SwiftUI

enum SocialV4Theme: String, CaseIterable, Identifiable {
    case overcast, linen, dusk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overcast: return "Overcast"
        case .linen: return "Linen"
        case .dusk: return "Dusk"
        }
    }

    var accent: Color {
        switch self {
        case .overcast: return Color(v4Hex: 0x8FD0FF)
        case .linen: return Color(v4Hex: 0xF4DDB0)
        case .dusk: return Color(v4Hex: 0xC9BBFF)
        }
    }

    var tabTint: Color {
        switch self {
        case .overcast: return Color(v4Hex: 0x343E54, opacity: 0.42)
        case .linen: return Color(v4Hex: 0x463D32, opacity: 0.42)
        case .dusk: return Color(v4Hex: 0x342C5C, opacity: 0.42)
        }
    }

    var bottom: Color {
        switch self {
        case .overcast: return Color(v4Hex: 0x272E3D)
        case .linen: return Color(v4Hex: 0x2D2924)
        case .dusk: return Color(v4Hex: 0x17132A)
        }
    }

    var gradientStops: [Color] {
        switch self {
        case .overcast:
            return [Color(v4Hex: 0x74839F), Color(v4Hex: 0x5A6884), Color(v4Hex: 0x3E4960), Color(v4Hex: 0x272E3D)]
        case .linen:
            return [Color(v4Hex: 0xA09079), Color(v4Hex: 0x82745F), Color(v4Hex: 0x544B3F), Color(v4Hex: 0x2D2924)]
        case .dusk:
            return [Color(v4Hex: 0x5E5292), Color(v4Hex: 0x463B78), Color(v4Hex: 0x2C244D), Color(v4Hex: 0x17132A)]
        }
    }

    static let breakColor = Color(v4Hex: 0xFFC56B)
    static let ink = Color(v4Hex: 0x15171D)
}

extension Color {
    init(v4Hex: UInt32, opacity: Double = 1) {
        let red = Double((v4Hex >> 16) & 0xFF) / 255
        let green = Double((v4Hex >> 8) & 0xFF) / 255
        let blue = Double(v4Hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension EnvironmentValues {
    @Entry var socialV4Theme: SocialV4Theme = .overcast
}

struct SocialV4Background: View {
    @Environment(\.socialV4Theme) private var theme

    var body: some View {
        let colors: [Color] = theme.gradientStops
        let locations: [CGFloat] = [0, 0.34, 0.68, 1]
        let stops: [Gradient.Stop] = zip(colors, locations).map { Gradient.Stop(color: $0, location: $1) }

        ZStack {
            LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [theme.accent.opacity(0.38), Color.clear],
                center: UnitPoint(x: 0.88, y: 0.04),
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}
