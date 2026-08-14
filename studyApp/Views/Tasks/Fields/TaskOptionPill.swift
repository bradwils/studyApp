//  TaskOptionPill.swift
//  studyApp
//
//  A single coloured chip for a select/multiSelect option. Used both as a read-only
//  label (TaskFieldCell) and as a tappable toggle (TaskFieldEditor's multiSelect grid).

import SwiftUI
import SwiftData

struct TaskOptionPill: View {
    let option: TaskFieldOption
    var isSelected: Bool = true

    // Falls back to gray rather than propagating nil — a malformed hex must never
    // be the reason a pill fails to render.
    private var tint: Color {
        Color(hex: option.colorHex) ?? .gray
    }

    var body: some View {
        Text(option.label)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isSelected ? tint : .secondary)
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.16) : Color.secondary.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? tint.opacity(0.5) : Color.secondary.opacity(0.25))
            )
    }
}

#Preview {
    HStack(spacing: 8) {
        TaskOptionPill(option: TaskFieldOption(label: "Canvas", colorHex: "#AF52DE", sortIndex: 0))
        TaskOptionPill(option: TaskFieldOption(label: "Blocked", colorHex: "#FF3B30", sortIndex: 1))
        TaskOptionPill(option: TaskFieldOption(label: "Reading", colorHex: "#A2845E", sortIndex: 2), isSelected: false)
        TaskOptionPill(option: TaskFieldOption(label: "Bad hex", colorHex: "not-a-color", sortIndex: 3))
    }
    .padding()
    .modelContainer(for: TaskSchema.models, inMemory: true)
}
