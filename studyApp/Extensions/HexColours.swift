//
//  HexColours.swift
//  studyApp
//
//  Created by brad wils on 29/1/26.
//


import Combine
import SwiftUI


extension Color { //colour extensionm allow for hex colors with Color(hex: "#E06910")
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // Optional: remove the leading '#' if present
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
