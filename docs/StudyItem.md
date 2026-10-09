# StudyItem

## Goal
A `StudyItem` is a task belonging to a Subject. It tracks:
- Baseline status (Not Started / In Progress / Completed / On Hold)
- Due date, priority, notes
- Subject-specific tracking fields (slider, text, number, tags, dropdown, date, time) — *which fields are enabled* and *what they're named* is per-Subject configuration, not per-item

Items persist their values for every possible field type; the UI shows only the fields the Subject has enabled via `SubjectFieldConfig`.

---

## Core Models

### StudyItem
```swift
@Model
final class StudyItem {
  id: UUID                      // unique id, @Unique constraint
  createdAt: Date               // set at init
  updatedAt: Date               // touches on any mutation
  completedAt: Date?            // set when status → Completed
  subject: Subject?             // reference (nullify on subject delete)
  
  // Configurable fields
  taskName: String              // task name
  notes: String?                // user notes
  
  // Array of typed field instances
  fields: [StudyItemField]       // values for fields configured on the subject
}
```

---

### StudyItemField
Container for one typed field instance. Each field holds a `FieldKind` enum that carries both the field's type and its value.

```swift
@Model
final class StudyItemField {
  var type: FieldKind
  
  init(type: FieldKind) {
    self.type = type
  }
}
```

---

## FieldKind Enum

`FieldKind` is an enum where each case wraps a struct containing exactly the properties that variant needs. One field = one case at a time.

```swift
enum FieldKind: Codable {
  case text(TextField)
  case number(NumberField)
  case slider(SliderField)
  case tag(TagField)
  case date(DateField)
  case time(TimeField)
  case dropdown(DropdownField)

  // ─── Nested Structs (one per case) ───
  
  struct TextField: Codable {
    var label: String
    var value: String
  }

  struct NumberField: Codable {
    var label: String
    var value: Double
  }

  struct SliderField: Codable {
    var label: String
    var value: Int
    var min: Int                // TODO: decide if required, optional, or default-valued
    var max: Int
    var step: Int
  }

  struct TagField: Codable {
    var label: String
    var selected: [String]      // user's selected tags (options from app-wide @Query)
  }

  struct DateField: Codable {
    var label: String
    var value: Date
  }

  struct TimeField: Codable {
    var label: String
    var value: TimeInterval
  }

  struct DropdownField: Codable {
    var label: String
    var selected: String        // user's chosen option (options from Subject config)
  }
}
```

---

## Subject Relationship

```swift
Subject (@Model) {
  @Relationship(deleteRule: .cascade)
  var fieldConfigs: [SubjectFieldConfig]    // defines which fields exist for this subject
  
  // ... existing properties ...
}
```

`SubjectFieldConfig` describes *which fields this subject has* and their configuration. When a `StudyItem` under that Subject needs a field instance, it stores its value in the corresponding `FieldKind` case.

---

## Data Flow & Ownership

```
StudyItem
  ├─ fields: [StudyItemField]
  │   └─ field.type: FieldKind  ← enum case (holds the typed struct with value)
  │       ├─ .text(TextField { label, value })
  │       ├─ .slider(SliderField { label, value, min, max, step })
  │       ├─ .tag(TagField { label, selected: [String] })
  │       ├─ .dropdown(DropdownField { label, selected })
  │       ├─ .date(DateField { label, value })
  │       ├─ .time(TimeField { label, value })
  │       └─ .number(NumberField { label, value })
  │
  └─ subject: Subject?
      └─ fieldConfigs: [SubjectFieldConfig]
          └─ defines *which* fields exist and their defaults
```

**Reading the flow:**
- `StudyItem.fields` is an array of `StudyItemField` instances — one per configured field on that item.
- Each instance's `type` is a `FieldKind` enum case that **carries its own typed struct** — `.slider(SliderField { ... })` holds exactly and only the data a slider needs.
- The pool of *available* field types for a Subject lives once on `Subject.fieldConfigs`, not duplicated per item.
- The `value`/`selected` inside each struct is the **instance-specific** data (e.g., the user set this particular slider to 42).

---

## Why Enums with Nested Structs

**Old approach** (antipattern):
```swift
var intValue: Int?
var doubleValue: Double?
var stringValue: String?
var selectedStrings: [String?]
var intMaxValue: Int?
var intStepValue: Int?
```
Problems: wasteful storage, no type safety, can accidentally access `intMaxValue` on a text field.

**New approach** (enum with associated structs):
```swift
case slider(SliderField)  // holds exactly a SliderField
case text(TextField)       // holds exactly a TextField
```
Benefits: only relevant properties per type, compiler type-safety, clean and obvious code.

---

## Design Notes

- **Tag options** are app-wide (fetched at render time via `@Query`)
- **Dropdown options** are subject-specific (stored on Subject, fetched at render time)
- **Slider min/max/step**: currently required per-field; can be optimized to defaults if Subject-wide defaults are added