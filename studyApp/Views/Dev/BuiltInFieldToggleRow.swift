//  DEV ONLY — see CLAUDE.md "Developer-Only Views".

import SwiftUI

struct BuiltInFieldToggleRow: View {
    let field: BuiltInField
    @AppStorage private var isEnabled: Bool

    init(_ field: BuiltInField) {
        self.field = field
        _isEnabled = AppStorage(wrappedValue: true, field.storageKey)
    }

    var body: some View {
        Toggle(isOn: $isEnabled) {
            Label(field.title, systemImage: field.systemImage)
        }
    }
}
