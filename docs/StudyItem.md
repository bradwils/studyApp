# StudyItems

StudyItems provide the SwiftData foundation for tasks, custom fields and shared
tags. The current UI is developer tooling under Debug Data; production task
screens and StudyItems integration with the Focus screen remain separate work.

## Stored data

- `StudyItem` stores its name, notes, status, due date, priority, timestamps and
  optional subject. `subjectName` preserves the name copied when assigning the
  subject if that subject is later deleted.
- `FieldDefinition` stores a name, plain `FieldType`, dropdown options, display
  order and enabled flag. Definitions are global, not subject-specific.
- `FieldValue` links one item to one definition and stores a `FieldContent`
  payload: text, number, date, duration in seconds or dropdown selection text.
- `Tag` is shared by items and field values. Its unique key is trimmed and
  lowercased; the developer VM reuses existing keys without replacing their colour.
- `AppSchema.models` registers these types alongside the existing app models.

`FieldKind` and its per-kind `FieldConfig` structs are reconstructed at runtime
from the definition's columns. They are not stored in SwiftData: persisting the
struct-bearing enum previously crashed when saving or loading field definitions.
`FieldContent` remains the persisted enum holding primitive values.

## Ownership

Deleting an item or definition cascades to its field values. Deleting a value
keeps its item, definition and tags. Deleting a subject or tag nullifies references
without deleting items. The inverse of each relationship is explicit on its
owning side.

The developer Delete All action fetches items and deletes them individually.
Batch deletion previously failed on the field-value inverse relationships.

## Editing behaviour

- Definition type is locked after creation. Dropdown options can be edited;
  comma-separated options are trimmed and deduplicated in first-seen order.
- Renaming or removing a dropdown option keeps existing selections visible in
  the editor so stored content is not silently discarded.
- Adding an already attached definition preserves the original value.
- The developer VM updates the item's `updatedAt` when built-in fields, custom
  values, subjects or status change. Models do not maintain timestamps themselves.
- Entering Completed sets `completedAt`; choosing Completed again preserves it.
  Reopening clears it, and completing again records a new date.
- Built-in visibility toggles use per-device `AppStorage`; disabling a built-in
  or custom field hides it without deleting data.

## Validation and migration

See [StudyItemTesting.md](StudyItemTesting.md) for the retained tests and review
status. The final feature combines the newer field-configuration work from #188
with the persistence tests and tag fixes from #190. The older V2 slot-based model
and its API-specific tests in #170 are an alternative implementation, not an
additional schema to combine with this one.

No versioned SwiftData schema or migration plan exists. Development installations
must be reinstalled/reseeded after adopting this schema. Versioning is deferred
to #163, before the first UAT release; `AppSchema` is only a shared model list.
