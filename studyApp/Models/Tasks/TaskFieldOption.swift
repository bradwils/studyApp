//  TaskFieldOption.swift
//  studyApp
//
//  A single choice in a select / multiSelect column.

import Foundation
import SwiftData

@Model
final class TaskFieldOption {
    var id: UUID = UUID()
    var label: String = ""          // "Canvas", "Physical worksheet", "Code"
    var colorHex: String = "#8E8E93"   // reuses Color(hex:) / toHex() from ThemeColorHex.swift — views convert, models don't
    var sortIndex: Int = 0

    init(id: UUID = UUID(), label: String = "", colorHex: String = "#8E8E93", sortIndex: Int = 0) {
        self.id = id
        self.label = label
        self.colorHex = colorHex
        self.sortIndex = sortIndex
    }
}
