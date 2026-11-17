import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if length == 6 {
            red = Double((rgb & 0xFF0000) >> 16) / 255.0
            green = Double((rgb & 0x00FF00) >> 8) / 255.0
            blue = Double(rgb & 0x0000FF) / 255.0
            alpha = 1.0
        } else if length == 8 {
            red = Double((rgb & 0xFF000000) >> 24) / 255.0
            green = Double((rgb & 0x00FF0000) >> 16) / 255.0
            blue = Double((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }

    func toHex() -> String? {
        guard let cgColor = self.cgColor,
              let components = cgColor.components,
              components.count >= 3 else {
            return nil
        }

        let red = Int(round(components[0] * 255.0))
        let green = Int(round(components[1] * 255.0))
        let blue = Int(round(components[2] * 255.0))
        let alpha = components.count >= 4 ? Int(round(components[3] * 255.0)) : 255

        if alpha == 255 {
            return String(format: "#%02X%02X%02X", red, green, blue)
        } else {
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        }
    }
}
