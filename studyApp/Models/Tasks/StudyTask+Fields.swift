//  StudyTask+Fields.swift
//  studyApp
//
//  The §4 accessor seam from docs/StudyTasks.md.

import Foundation
import SwiftData

// Where a value is stored and whether a column is shown are two different questions.
// Five fields (title, isDone, completedAt, dueDate, sortIndex) are real typed properties
// on StudyTask — the whole app needs to sort, filter and reason about them. Every other
// column a subject configures for itself lives sparsely in a TaskFieldValue row, matched
// to its column by `definition`. `column.coreKey` is the switch: non-nil means read/write
// the typed property; nil means find (or lazily create) the matching TaskFieldValue and
// use the slot `column.kind` calls for. This is the ONLY place in the codebase that knows
// values can live in two places — every view goes through content(for:)/setContent(...)
// and never touches a TaskFieldValue directly.
extension StudyTask {
    func content(for column: TaskFieldDefinition) -> TaskFieldContent {
        if let coreKey = column.coreKey {
            switch coreKey {
            case .title:
                return .text(title)
            case .dueDate:
                guard let dueDate else { return .empty }
                return .date(dueDate)
            case .isDone:
                return .flag(isDone)
            }
        }

        guard let value = fieldValues?.first(where: { $0.definition?.id == column.id }) else {
            return .empty
        }

        switch column.kind {
        case .text:
            guard let textValue = value.textValue else { return .empty }
            return .text(textValue)
        case .date:
            guard let dateValue = value.dateValue else { return .empty }
            return .date(dateValue)
        case .checkbox:
            guard let boolValue = value.boolValue else { return .empty }
            return .flag(boolValue)
        case .select, .multiSelect:
            guard let options = value.selectedOptions, !options.isEmpty else { return .empty }
            return .options(options)
        case .number, .scale:
            guard let numberValue = value.numberValue else { return .empty }
            return .number(numberValue)
        }
    }

    func setContent(_ content: TaskFieldContent, for column: TaskFieldDefinition, context: ModelContext) {
        if let coreKey = column.coreKey {
            setCoreContent(content, for: coreKey)
            return
        }

        let existing = fieldValues?.first(where: { $0.definition?.id == column.id })

        if case .empty = content {
            // Nothing to clear and nothing to allocate — an untouched column stays untouched.
            guard let existing else { return }
            clearSlot(of: existing, kind: column.kind)
            return
        }

        // Validate before allocating anything — a mismatched write (e.g. `.text` sent to a
        // `.date` column) must be a silent no-op, not an empty row left behind.
        guard matches(content, kind: column.kind) else { return }

        let value: TaskFieldValue
        if let existing {
            value = existing
        } else {
            value = TaskFieldValue(definition: column, task: self)
            context.insert(value)
            if fieldValues == nil {
                fieldValues = [value]
            } else {
                fieldValues?.append(value)
            }
        }

        switch content {
        case .text(let text):
            value.textValue = text
        case .date(let date):
            value.dateValue = date
        case .flag(let flag):
            value.boolValue = flag
        case .number(let number):
            value.numberValue = number
        case .options(let options):
            // select allows exactly one — truncate defensively even though the layout
            // editor (Phase 2) is what's expected to enforce this in the first place.
            value.selectedOptions = column.kind == .select ? Array(options.prefix(1)) : options
        case .empty:
            break // handled above
        }
    }

    private func setCoreContent(_ content: TaskFieldContent, for coreKey: TaskCoreField) {
        switch coreKey {
        case .title:
            guard case .text(let text) = content else { return }
            title = text
        case .dueDate:
            switch content {
            case .empty: dueDate = nil
            case .date(let date): dueDate = date
            default: return
            }
        case .isDone:
            // The isDone <-> completedAt invariant lives here so no caller can forget it.
            // Only the transition stamps: re-affirming an already-done task must not move
            // completedAt, or "time to complete" drifts every time the row is touched.
            guard case .flag(let flag) = content, flag != isDone else { return }
            isDone = flag
            completedAt = flag ? Date.now : nil
        }
    }

    private func matches(_ content: TaskFieldContent, kind: TaskFieldKind) -> Bool {
        switch (kind, content) {
        case (.text, .text): return true
        case (.date, .date): return true
        case (.checkbox, .flag): return true
        case (.select, .options), (.multiSelect, .options): return true
        case (.number, .number), (.scale, .number): return true
        default: return false
        }
    }

    private func clearSlot(of value: TaskFieldValue, kind: TaskFieldKind) {
        switch kind {
        case .text: value.textValue = nil
        case .date: value.dateValue = nil
        case .checkbox: value.boolValue = nil
        case .select, .multiSelect: value.selectedOptions = nil
        case .number, .scale: value.numberValue = nil
        }
    }
}
