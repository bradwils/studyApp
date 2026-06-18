# AppTheme

## Overview
`AppTheme` is a SwiftData model representing a saved color palette (primary/secondary/accent) for the app's UI. Colors are stored as hex strings since SwiftData can't persist `SwiftUI.Color` directly, and exposed back out as `Color` via computed properties.

## Properties
| Name | Type | Description |
|------|------|-------------|
| `name` | `String` | Theme name, e.g. `"Summer"` |
| `primaryColorHex` | `String` (private) | Hex-encoded primary color |
| `secondaryColorHex` | `String` (private) | Hex-encoded secondary color |
| `accentColorHex` | `String` (private) | Hex-encoded accent color |
| `primaryColor` | `Color` | Computed accessor over `primaryColorHex`; falls back to `.white` if decoding fails |
| `secondaryColor` | `Color` | Computed accessor over `secondaryColorHex`; falls back to `.blue` |
| `accentColor` | `Color` | Computed accessor over `accentColorHex`; falls back to `.gray` |

The hex conversion itself lives in a `Color` extension (`Models/Backend/ThemeColorHex.swift`), not on the model.

## Initializers

### Designated Initializer
```swift
init(name: String, primary: Color, secondary: Color, accent: Color)
```
Takes `Color` values directly and converts them to hex internally; all three colors fall back to a default hex if `toHex()` fails.

## SwiftData Relationship
- Registered directly in the app's `modelContainer` (see [StudyAppApp.swift](../../../studyApp/App/StudyAppApp.swift)).
- Standalone — `AppTheme` has no relationships to `Subject`, `StudySession`, or `UserProfile`.

## Used Flows
- `ThemeSettingsViewModel` (`ViewModels/Settings/ThemeSettingsViewModel.swift`) seeds three default themes ("Summer", "Winter", "Dummy") into the model context on first launch if none exist, and fetches all themes sorted by name for the Settings UI.
