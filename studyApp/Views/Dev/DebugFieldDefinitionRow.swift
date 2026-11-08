//  DEV ONLY — see CLAUDE.md "Developer-Only Views".

import SwiftUI

struct DebugFieldDefinitionRow: View {
    @Bindable var definition: FieldDefinition

    var body: some View {
        Toggle(isOn: $definition.isEnabled) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(definition.name).font(.headline)
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: definition.kind.systemImage)
            }
        }
    }

    private var summary: String {
        var parts = [definition.kind.rawValue]
        if definition.kind == .dropdown { parts.append(definition.options.joined(separator: " / ")) }
        parts.append("\(definition.values.count) value(s)")
        return parts.joined(separator: " · ")
    }
}
