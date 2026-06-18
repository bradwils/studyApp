# SessionLocation

## Overview
SessionLocation is a SwiftData model that captures location metadata for a study session. It stores geographic coordinates and a descriptive label for where a user studied. Currently a placeholder for future location-tagging features — no view in the app creates or reads one yet.

## Properties
| Name | Type | Description |
|------|------|-------------|
| `locationDescription` | `String?` | User-friendly description of the location |
| `latitude` | `Double?` | Geographic latitude coordinate |
| `longitude` | `Double?` | Geographic longitude coordinate |
| `locationLabel` | `String` | Short tag/label for the location |

## Initializers

### Designated Initializer
```swift
init(locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil, locationLabel: String)
```
Full control over all fields. `locationLabel` is the only required parameter.

### Convenience Initializers
```swift
convenience init(latitude: Double, longitude: Double)
```
Quick initialization with just coordinates. Description defaults to `nil`, label defaults to `""`.

```swift
convenience init()
```
Placeholder initializer for testing or default cases. Creates a dummy location with placeholder values.

## SwiftData Relationship
- **Embedded in**: `StudySession.location` (optional, one-to-one)
- **Used for**: Tagging where a study session occurred
- Registered directly in the app's `modelContainer` (see [StudyAppApp.swift](../../../studyApp/App/StudyAppApp.swift))
