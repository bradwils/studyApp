//
//  HexColours.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//


import SwiftUI

extension Color {
    
    // MARK: - Hex String to Color
    /// Initializes a SwiftUI Color from a Hex string.
    /// Supports both 6-character (RGB) and 8-character (RGBA) formats.
    init?(hex: String) {
        // 1. Remove any whitespaces and the '#' symbol
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        // 2. Prepare a variable to hold the parsed integer value
        var rgb: UInt64 = 0
        
        // 3. Scan the hex string into the UInt64 variable
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        // 4. Extract the color components based on the string length
        if length == 6 {
            // Standard 6-character hex (e.g., "FF0000" for red)
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0 // Default to fully opaque
        } else if length == 8 {
            // 8-character hex with alpha (e.g., "FF000080" for 50% transparent red)
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            // Invalid length
            return nil
        }
        
        // 5. Initialize the native SwiftUI Color
        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    // MARK: - Color to Hex String
    /// Converts a SwiftUI Color to a Hex string.
    /// Returns an 8-character string if there is transparency, otherwise a 6-character string.
    func toHex() -> String? {
        // 1. Get the underlying CGColor (Available iOS 14+)
        // This is the cleanest way to get color components without UIKit/AppKit
        guard let cgColor = self.cgColor,
              let components = cgColor.components,
              components.count >= 3 else {
            return nil
        }
        
        // 2. Extract the RGB values and convert them to a 0-255 scale
        let r = Int(round(components[0] * 255.0))
        let g = Int(round(components[1] * 255.0))
        let b = Int(round(components[2] * 255.0))
        
        // 3. Extract the alpha (opacity) value if it exists, default to fully opaque
        let a = components.count >= 4 ? Int(round(components[3] * 255.0)) : 255
        
        // 4. Format the output string
        if a == 255 {
            // No transparency, return standard 6-character hex
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            // Includes transparency, return 8-character hex
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
    }
}
