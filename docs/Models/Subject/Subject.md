# Subject

## Overview
`Subject` represents a single study subject (e.g. "Mathematics", code `MATH101`). It's the smallest model in the app, but the most widely referenced — sessions, the subjects editor, and the social feed all key off it.

## Properties
| Name | Type | Description |
|------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | Display name, e.g. `"Mathematics"` |
| `code` | `String` | Short code, e.g. `"MATH101"`; stored uppercased by `SubjectsEditorVM` |
| `createdAt` | `Date` | Creation timestamp |

## Initializers

### Designated Initializer
```swift
init(id: UUID = UUID(), name: String, code: String, createdAt: Date = Date())
```
Only `name` and `code` are required; `id` and `createdAt` default sensibly.

## SwiftData Relationship
- Registered directly in the app's `modelContainer` (see [StudyAppApp.swift](../../../studyApp/App/StudyAppApp.swift)).
- Referenced optionally by [`StudySession.subject`](../StudySession/StudySession.md) (many sessions to one subject; no cascade delete rule declared).
- `UserProfile.subjects` also holds an array of `Subject` (see [UserProfile.md](../UserProfile/UserProfile.md)), but via the legacy JSON store rather than SwiftData.

## Used Flows
- `SubjectsEditorVM` (`ViewModels/Settings/SubjectsEditorVM.swift`) is the only place subjects are created or deleted today, gated by `canAddSubject` (1–32 char name, 1–4 char code).
- `SubjectStore` (`ViewModels/SubjectStore.swift`) is a parallel, legacy JSON-backed store for `Subject` arrays, kept for backwards compatibility while the SwiftData migration is in progress — new code should prefer `@Query`/`ModelContext` over this store.
