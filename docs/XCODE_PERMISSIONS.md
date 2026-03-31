# Xcode Permissions and Setup Checklist

## Required Permissions

Live Activities require **minimal permissions**. Here's what you need:

### ✅ Info.plist Entry (REQUIRED)

**Key**: `NSSupportsLiveActivities`
**Type**: Boolean
**Value**: `YES`

#### How to Add:

**Method 1: Using Xcode UI (Easiest)**
1. Open `studyApp.xcodeproj` in Xcode
2. Select the **studyApp** target in the project navigator
3. Go to the **Info** tab
4. Right-click in the "Custom iOS Target Properties" section
5. Click **Add Row**
6. Start typing "Supports Live Activities" - it should autocomplete to `NSSupportsLiveActivities`
7. Set the value to **YES** (checkmark)

**Method 2: Edit Info.plist File Directly**
If you have a physical Info.plist file:
1. Open `studyApp/Info.plist` in Xcode
2. Add this entry:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### ✅ iOS Deployment Target (REQUIRED)

**Minimum Version**: iOS 16.1

#### How to Verify:
1. Open project in Xcode
2. Select **studyApp** target
3. Go to **General** tab
4. Find **Minimum Deployments** section
5. Check **iOS** is set to **16.1** or higher

If it's lower than 16.1:
1. Change the dropdown to **16.1** or higher
2. Click outside to save

## Optional Capabilities

### Background Modes (Optional but Recommended)

While not strictly required, enabling background modes can help keep the Live Activity updated:

1. Select **studyApp** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** button
4. Search for "Background Modes"
5. Add it to your target
6. Check **Background fetch**

**Why?** Helps the system keep your Live Activity fresh when the app is in the background.

## No Other Permissions Needed!

Unlike some features, Live Activities do NOT require:
- ❌ User notification permission
- ❌ Location permission
- ❌ Background app refresh permission (though it helps)
- ❌ Widget extension capability
- ❌ App Groups (only needed for widget extensions)
- ❌ Push notifications (unless using push-updated Live Activities)

## User Settings

Once you build and run your app, users can control Live Activities in:

**Settings → studyApp → Live Activities**

They'll see a toggle:
- **ON**: Live Activities will appear (default)
- **OFF**: No Live Activities will show

**Note**: This is a system-level setting. Your app checks this automatically with:
```swift
ActivityAuthorizationInfo().areActivitiesEnabled
```

## Complete Setup Checklist

### Before Building:
- [ ] Add `NSSupportsLiveActivities = YES` to Info.plist
- [ ] Verify iOS deployment target is 16.1+
- [ ] Ensure all new Swift files are in the target (check Target Membership)

### After Building:
- [ ] Install app on device or simulator
- [ ] Check Settings → studyApp → ensure Live Activities toggle exists
- [ ] Enable Live Activities toggle if it's off

### Testing:
- [ ] Start a study session
- [ ] Lock the device (Cmd+L on simulator)
- [ ] Verify Live Activity appears on Lock Screen
- [ ] Unlock and pause the session
- [ ] Lock again and verify "Paused" status
- [ ] Unlock and end session
- [ ] Lock again and verify Live Activity disappeared

## Troubleshooting Permissions

### "Live Activities are not enabled" in console
**Cause**: User disabled Live Activities in Settings
**Fix**: Settings → studyApp → Live Activities → ON

### "ActivityKit not found" build error
**Cause**: Deployment target too low
**Fix**: Set deployment target to iOS 16.1 or higher

### "No such module 'ActivityKit'" error
**Cause**: Deployment target or import issue
**Fix**:
1. Clean build folder (Cmd+Shift+K)
2. Verify deployment target is 16.1+
3. Rebuild (Cmd+B)

### Live Activity doesn't appear after starting session
**Checks**:
1. Console shows "✅ Live Activity started: [ID]"?
   - If yes: Check Settings → Live Activities
   - If no: Check console for error message
2. Info.plist has NSSupportsLiveActivities = YES?
3. iOS version is 16.1+?
4. Lock the screen after starting session?

## Development Device Requirements

### Simulator
- **macOS**: Ventura (13.0) or later
- **Xcode**: 14.1 or later
- **Simulator**: iOS 16.1 or later

### Physical Device
- **iPhone**: Any model running iOS 16.1 or later
- **Dynamic Island**: iPhone 14 Pro, 14 Pro Max, 15 Pro, 15 Pro Max, or later
- **iOS Version**: 16.1 minimum (17.0+ recommended)

## Summary

**Total permissions needed**: **1** (just the Info.plist entry)

**Total time to setup**: **~2 minutes**

**Steps**:
1. Add Info.plist entry
2. Verify deployment target
3. Build and run

That's it! No complex permission requests or user prompts needed.

---

## Quick Reference

| Permission | Required? | Where to Set |
|------------|-----------|--------------|
| NSSupportsLiveActivities | ✅ YES | Info.plist |
| iOS 16.1+ Deployment | ✅ YES | Target → General |
| Background Modes | ⚪ Optional | Target → Capabilities |
| User Notification | ❌ NO | - |
| Location Services | ❌ NO | - |
| App Groups | ❌ NO | - |

---

**You're all set!** Just add the Info.plist entry and you're ready to go.
