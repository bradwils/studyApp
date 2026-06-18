# UserProfile

## Overview
`UserProfile` holds all local data for the app's single local user, plus an optional link to a future remote/auth account. Unlike `Subject` and `StudySession`, it is a plain `Codable` struct, not a SwiftData `@Model` — it's persisted manually as JSON by `UserProfileStore`, which is one of the legacy stores the codebase is migrating away from (see root `CLAUDE.md`).

## Properties
| Name | Type | Description |
|------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `userHandle` | `String?` | Reserved for a future online handle |
| `userStatus` | `ActiveStatus` | Current activity state |
| `profileName` | `String` | Display name |
| `userProfilePicturePath` | `String?` | Local path to a profile picture |
| `auth` | `AuthState` | Sign-in provider and last sign-in time |
| `createdAt` | `Date` | Profile creation timestamp |
| `isPaused` | `Bool` | Whether the user's activity is currently paused |
| `lastResumedAt` | `Date` | When activity was last resumed |
| `lastActiveAt` | `Date` | Updated on every store mutation |
| `subjects` | `[Subject]` | The user's subjects |
| `studySessions` | `[StudySession]` | The user's sessions (defaults to `[]`) |

### Supporting Types

**`AuthState`** — `Codable` struct
| Name | Type | Description |
|------|------|-------------|
| `service` | `AuthProvider?` | Which provider the user signed in with, if any |
| `lastSignInAt` | `Date?` | Last sign-in timestamp |

**`AuthProvider`** — `String`-backed `Codable, CaseIterable` enum
`apple`, `google`, `emailPassword`, `custom`, `anon` (no sign-in).

**`ActiveStatus`** — `String`-backed `Codable` enum
`offline`, `paused`, `online`, `studying`.

## SwiftData Relationship
`UserProfile` is **not** registered in the app's `modelContainer` and has no SwiftData relationships. Its `subjects` and `studySessions` arrays embed the SwiftData model types directly, which is a known gap in the migration: neither `Subject` nor `StudySession` currently declares `Codable` conformance, so encoding/decoding a `UserProfile` containing them is unlikely to work as written.

## Used Flows
- `UserProfileStore` (`ViewModels/UserProfileStore.swift`) is a singleton (`UserProfileStore.shared`) that loads/saves `UserProfile` as JSON to `userProfile.json`, seeding three sample subjects in `DEBUG` builds and migrating from a legacy `subjectsList.json` file if present.
- `addSubject`, `removeSubject`, and `updateProfile` all touch `lastActiveAt` and re-save on every call.

See [Models overview](../README.md) for how this legacy JSON path relates to the SwiftData-backed models.
