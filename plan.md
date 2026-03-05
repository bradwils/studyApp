# Plan: Inject UserProfileStore into SwiftUI Environment

**TL;DR:**
Expose `UserProfileStore` at the app root via `@StateObject` and `.environmentObject()` so all views can access it without tight coupling to the singleton. This makes the store tree-wide accessible, improves testability, and removes the need for views to call `UserProfileStore.shared` directly. We'll audit existing views to update them from singleton access to `@EnvironmentObject`.

## Steps

1. **Update [StudyAppApp.swift](studyApp/App/StudyAppApp.swift)**
   - Add `@StateObject var userStore = UserProfileStore.shared`
   - Inject via `.environmentObject(userStore)` on `MainTabView()`

2. **Audit existing usage of `UserProfileStore.shared`**
   - Search codebase for all references to `UserProfileStore.shared`
   - Document which ViewModels and Views use it
   - Identify which should switch to `@EnvironmentObject` vs. which should keep singleton access (e.g., if a ViewModel is used outside SwiftUI context)

3. **Update ViewModels that use the store**
   - For ViewModels like `UserProfileStore`, `SubjectStore`, `StudyTrackingViewModel` that need the user store:
     - Remove direct `UserProfileStore.shared` calls
     - Inject store as a parameter in `init()` instead
     - Views provide the store from `@EnvironmentObject`

4. **Update Views that directly access the store**
   - Replace `@StateObject private var store = UserProfileStore.shared` with `@EnvironmentObject var store: UserProfileStore`
   - Remove any direct singleton calls

5. **Test environment injection**
   - Verify the app launches without crashes
   - Check that changes to profile persist correctly
   - Test in previews by passing a mock `UserProfileStore` as `.environmentObject(mockStore)`

## Verification

- App builds and runs
- Profile changes save to disk automatically
- Previews work by injecting test stores
- No "Fatal error: No ObservedObject of type UserProfileStore" warnings

## Decisions

- Chose environment injection over singleton to enable dependency injection and testability
- `UserProfileStore.shared` stays as a default initializer (fallback for app root), not removed entirely
