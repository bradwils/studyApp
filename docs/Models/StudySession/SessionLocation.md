# SessionLocation

## Overview
SessionLocation is a SwiftData Model that captures location metadata for a study session. It stores geographic coordinates and descriptive labels for where a user studied. Currently a placeholder for future location tagging features.

## Properties
| Name | Type | Description |
|------|------|-------------|
| `locationDescription` | `String?` | User-friendly description of the location |
| `latitude` | `Double?` | Geographic latitude coordinate |
| `longitude` | `Double?` | Geographic longitude coordinate |
| `locationLabel` | `String?` | Short tag/label for the location |

## Initializers

### Designated Initializer
```swift
init(locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil, locationLabel: String? = nil)
```
Full control over all fields. All parameters are optional with nil defaults.

### Convenience Initializers
```swift
convenience init(latitude: Double, longitude: Double)
```
Quick initialization with just coordinates. Location description and label default to nil.

```swift
convenience init()
```
Placeholder initializer for testing or default cases. Creates a dummy location with placeholder values.

## SwiftData Relationship
- **Embedded in**: `StudySession.location` (optional relationship)
- **Used for**: Tagging where a study session occurred
