//  DEV ONLY — see CLAUDE.md "Developer-Only Views".

import SwiftUI

/// Shows its content only while the built-in field is enabled in the fields browser.
struct BuiltInFieldGate<Content: View>: View {
    @AppStorage private var isEnabled: Bool
    private let content: Content

    init(_ field: BuiltInField, @ViewBuilder content: () -> Content) {
        _isEnabled = AppStorage(wrappedValue: true, field.storageKey)
        self.content = content()
    }

    var body: some View {
        if isEnabled { content }
    }
}
