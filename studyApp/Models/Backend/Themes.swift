import SwiftData

@Model
final class AppTheme {
    var name: String
    var primaryColorHex: String
    var secondaryColorHex: String
    var accentColorHex: String

    init(name: String, primaryColorHex: String, secondaryColorHex: String, accentColorHex: String) {
        self.name = name
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.accentColorHex = accentColorHex
    }
}
