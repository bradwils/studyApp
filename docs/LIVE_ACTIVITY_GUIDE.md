# Live Activity Implementation Guide

## Overview

This document explains how the Live Activity feature works in the studyApp and how to set it up properly. Live Activities allow you to display real-time study session information on your iPhone's Lock Screen and Dynamic Island (iPhone 14 Pro and later).

## What is a Live Activity?

A Live Activity is a special type of widget that:
- Displays real-time information on your Lock Screen
- Shows minimal information in the Dynamic Island on supported devices
- Updates automatically as your study session progresses
- Remains visible even when your phone is locked

## Features Implemented

The Live Activity for studyApp displays:
- **Subject name and code** (e.g., "Mathematics - MATH101")
- **Current session duration** (updates every second)
- **Pause/Play status** (visual indicator when paused)
- **Interruption count** (if any interruptions occurred)
- **Total break duration** (if any breaks were taken)

## Files Created

### 1. StudySessionAttributes.swift
**Location:** `/studyApp/Models/StudySessionAttributes.swift`

This file defines the data structure for the Live Activity:
- **Attributes**: Static data that doesn't change (session ID)
- **ContentState**: Dynamic data that updates during the session (duration, pause state, etc.)

### 2. StudySessionLiveActivity.swift
**Location:** `/studyApp/Widgets/StudySessionLiveActivity.swift`

This file defines the UI for the Live Activity:
- **Lock Screen view**: Full-width display showing subject, duration, and status
- **Dynamic Island compact view**: Small icon and timer
- **Dynamic Island expanded view**: Detailed information with metrics
- **Dynamic Island minimal view**: Just an icon when multiple activities are active

### 3. Updated StudyTrackingViewModel.swift
**Location:** `/studyApp/ViewModels/StudyTrackingViewModel.swift`

Added Live Activity lifecycle management:
- `startLiveActivity()`: Creates and starts the Live Activity
- `updateLiveActivity()`: Updates the Live Activity every second
- `endLiveActivity()`: Dismisses the Live Activity when session ends

## How It Works

### Lifecycle

1. **Start Session**: When you tap "Start" in the app
   - A new `StudySession` is created
   - The Live Activity is automatically started
   - The Lock Screen widget appears

2. **During Session**: Every second while studying
   - The timer updates the session duration
   - The Live Activity updates automatically
   - Pause/resume actions update the UI state

3. **End Session**: When you tap "End" or cancel
   - The session is finalized
   - The Live Activity is dismissed
   - The Lock Screen widget disappears

### Data Flow

```
User Action → StudyTrackingViewModel → Live Activity API → System UI
    ↓                    ↓                      ↓              ↓
  Start             activeSession          Activity.request   Lock Screen
  Pause            isPaused = true          activity.update   Dynamic Island
  Resume           isPaused = false         activity.update   Updated UI
  End              activeSession = nil      activity.end      Dismissed
```

## Xcode Setup Required

### Step 1: Add ActivityKit Framework

The code already imports `ActivityKit`, but you need to ensure your project links to it:

1. Open `studyApp.xcodeproj` in Xcode
2. Select the **studyApp** target
3. Go to **General** → **Frameworks, Libraries, and Embedded Content**
4. If `ActivityKit.framework` is not listed, click **+** and add it
5. Ensure it's set to "Do Not Embed"

### Step 2: Enable Live Activities in Info.plist

You need to add a key to enable Live Activities:

1. Open your `Info.plist` file (or use the Info tab in your target settings)
2. Add a new key: **NSSupportsLiveActivities**
3. Set the type to **Boolean**
4. Set the value to **YES**

**XML format (if editing Info.plist directly):**
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### Step 3: Configure Project Capabilities

Live Activities don't require special entitlements, but they do require:

1. **Minimum iOS version**: iOS 16.1 or later
   - Check your deployment target: Target → General → Minimum Deployments
   - Should be set to iOS 16.1 or higher

2. **Background Modes** (optional, but recommended):
   - Go to Target → Signing & Capabilities
   - Click **+ Capability**
   - Add **Background Modes**
   - Enable **Background fetch** (helps keep the activity updated)

### Step 4: Add Files to Target

Ensure the new files are included in your target:

1. In Xcode, select `StudySessionAttributes.swift`
2. In the File Inspector (right panel), ensure **Target Membership** includes `studyApp`
3. Repeat for `StudySessionLiveActivity.swift`

### Step 5: Build Settings

Check your build settings:

1. Go to Target → Build Settings
2. Search for "ActivityKit"
3. Ensure nothing is blocking the framework

## Testing the Live Activity

### On Simulator (iOS 16.1+)

1. **Build and run** the app on a simulator running iOS 16.1 or later
2. **Start a study session** by selecting a subject and tapping "Start"
3. **Lock the simulator**: Hardware → Lock (or Cmd+L)
4. You should see the Live Activity on the Lock Screen

### On Physical Device (Recommended)

Live Activities work best on actual devices:

1. **Connect your iPhone** (iPhone 14 Pro or later for Dynamic Island)
2. **Build and run** the app on your device
3. **Enable Live Activities** (if prompted):
   - Settings → studyApp → Live Activities → ON
4. **Start a study session**
5. **Lock your phone** to see the Lock Screen widget
6. On iPhone 14 Pro+, the Dynamic Island will show the timer

### Testing Different States

1. **Pause**: Tap the pause button - the widget should show "Paused" and orange color
2. **Resume**: Tap resume - the widget should show "Studying" and green/blue color
3. **Interruptions**: Tap the interruption button - the count should appear in the widget
4. **End**: Tap the end button - the widget should disappear

## Permissions & User Settings

### System Permissions

Live Activities don't require explicit user permission, but users can disable them:

**Settings → studyApp → Live Activities**
- ON: Live Activities will appear
- OFF: No Live Activities will show (the app still works normally)

### Checking Permission Status

The code already checks if Live Activities are enabled:

```swift
guard ActivityAuthorizationInfo().areActivitiesEnabled else {
    print("Live Activities are not enabled")
    return
}
```

If disabled, the app will still work but won't show the Live Activity.

## Troubleshooting

### Live Activity doesn't appear

1. **Check iOS version**: Must be iOS 16.1 or later
2. **Check Info.plist**: Ensure `NSSupportsLiveActivities` is set to YES
3. **Check permissions**: Settings → studyApp → Live Activities must be ON
4. **Check console**: Look for "Live Activities are not enabled" message
5. **Rebuild the app**: Clean build folder (Cmd+Shift+K) and rebuild

### Live Activity doesn't update

1. **Check timer**: Ensure the session ticker is running (1 Hz updates)
2. **Check console**: Look for update errors
3. **Session state**: Ensure `activeSession` is not nil

### UI looks wrong

1. **Check device**: Dynamic Island only works on iPhone 14 Pro and later
2. **Other devices**: Will show Lock Screen view only
3. **Colors**: May appear different on Lock Screen vs Dynamic Island

## Design Decisions

### Why Simple Design?

The Live Activity intentionally has a clean, minimal design:
- **Easy to read at a glance** on the Lock Screen
- **No clutter** - only essential information
- **Consistent colors**: Blue for active, orange for paused, green for status
- **Monospaced digits**: Timer is easier to read with uniform spacing

### Why Update Every Second?

The Live Activity updates every second (matching the session ticker) to:
- Keep the displayed time accurate
- Show real-time progress
- Maintain consistency with the in-app timer

### Why Immediate Dismissal?

When a session ends, the Live Activity dismisses immediately because:
- The session is over - no more data to display
- Prevents stale information on Lock Screen
- User can see session summary in the app

## Advanced Customization

### Changing Colors

Edit `StudySessionLiveActivity.swift`:

```swift
.foregroundColor(.blue)  // Change to your preferred color
```

### Changing Timer Format

Edit the `formatDuration()` function:

```swift
private func formatDuration(_ duration: TimeInterval) -> String {
    // Customize format here
}
```

### Adding More Metrics

Update `StudySessionAttributes.ContentState`:

```swift
public struct ContentState: Codable, Hashable {
    // Add new fields here
    var yourNewField: String
}
```

Then update the Live Activity UI to display them.

## Code Organization

```
studyApp/
├── Models/
│   └── StudySessionAttributes.swift      # Live Activity data structure
├── Widgets/
│   └── StudySessionLiveActivity.swift    # Live Activity UI
└── ViewModels/
    └── StudyTrackingViewModel.swift      # Live Activity lifecycle
```

## Summary

The Live Activity feature is now fully integrated into studyApp. It automatically:
- ✅ Starts when you begin studying
- ✅ Updates every second with current duration
- ✅ Shows pause/resume state
- ✅ Displays interruptions and breaks
- ✅ Ends when you finish the session

**No manual intervention required** - just start studying and the Live Activity appears!

## Next Steps

1. **Add Info.plist key**: `NSSupportsLiveActivities = YES`
2. **Test on device**: Build and run on iPhone
3. **Customize if needed**: Adjust colors or layout to match your preferences

---

*Created: March 31, 2026*
*Feature: Live Activity for Study Sessions*
*Minimum iOS: 16.1*
