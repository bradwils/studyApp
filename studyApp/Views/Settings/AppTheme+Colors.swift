import SwiftUI

extension AppTheme {
    convenience init(name: String, primary: Color, secondary: Color, accent: Color) {
        self.init(
            name: name,
            primaryColorHex: primary.toHex() ?? "#FFFFFF",
            secondaryColorHex: secondary.toHex() ?? "#0000FF",
            accentColorHex: accent.toHex() ?? "#808080"
        )
    }

    // MARK: - Computed Color Properties

    /// Returns the primary color as a SwiftUI Color
    var primaryColor: Color {
        get {
            Color(hex: primaryColorHex) ?? .white
        }
        set {
            primaryColorHex = newValue.toHex() ?? "#FFFFFF"
        }
    }

    /// Returns the secondary color as a SwiftUI Color
    var secondaryColor: Color {
        get {
            Color(hex: secondaryColorHex) ?? .blue
        }
        set {
            secondaryColorHex = newValue.toHex() ?? "#0000FF"
        }
    }

    /// Returns the accent color as a SwiftUI Color
    var accentColor: Color {
        get {
            Color(hex: accentColorHex) ?? .gray
        }
        set {
            accentColorHex = newValue.toHex() ?? "#808080"
        }
    }
}
