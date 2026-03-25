import SwiftData
import SwiftUI


//Our app theme. Each app theme is a model, and automatically stored using SwiftData.
//Container: where we store our themes
// - needs to be injected at the app layer

//Context: how we interact with our themes.

@Model
class AppTheme {
    var name: String
    
    // Store as hex strings for SwiftData persistence
    private var primaryColorHex: String
    private var secondaryColorHex: String
    private var accentColorHex: String

    init(name: String, prim: Color, sec: Color, acc: Color) {
        self.name = name
        self.primaryColorHex = prim.toHex() ?? "#FFFFFF"
        self.secondaryColorHex = sec.toHex() ?? "#0000FF"
        self.accentColorHex = acc.toHex() ?? "#808080"
    }
    
    // MARK: - Computed Color Properties
    
    /// Returns the primary color as a SwiftUI Color
    var primaryColor: Color {
        get {
            Color(hex: primaryColorHex) ?? .white //returns a color from the hex value stored
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
