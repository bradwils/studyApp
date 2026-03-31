# Quick Setup Checklist for Live Activities

## ⚡ Quick Start (5 minutes)

Follow these steps to enable Live Activities in your Xcode project:

### ✅ Step 1: Add Info.plist Entry

1. Open Xcode
2. Navigate to your target settings: **studyApp target → Info tab**
3. Right-click in the Custom iOS Target Properties area
4. Select **Add Row**
5. Key: Type `NSSupportsLiveActivities` (or select "Supports Live Activities" from dropdown)
6. Type: **Boolean**
7. Value: **YES** ✓

**Alternative (edit Info.plist file directly):**

If you have an `Info.plist` file in your project, add this entry:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### ✅ Step 2: Verify iOS Deployment Target

1. Go to **studyApp target → General tab**
2. Find **Minimum Deployments**
3. Ensure **iOS** is set to **16.1** or higher

### ✅ Step 3: Verify Files Are in Target

1. Select `StudySessionAttributes.swift` in the Project Navigator
2. Check the **File Inspector** (right sidebar)
3. Under **Target Membership**, ensure **studyApp** is checked ✓
4. Repeat for `StudySessionLiveActivity.swift`

### ✅ Step 4: Build and Test

1. **Clean build folder**: Cmd+Shift+K
2. **Build**: Cmd+B
3. **Run on device or simulator**: Cmd+R
4. **Start a study session** in the app
5. **Lock your device/simulator**: Cmd+L (simulator) or Side button (device)
6. **Check Lock Screen** - you should see the Live Activity!

## 🎯 Testing Checklist

- [ ] Live Activity appears when session starts
- [ ] Timer updates every second
- [ ] Pausing shows "Paused" and orange color
- [ ] Resuming shows "Studying" and blue/green color
- [ ] Ending session dismisses the Live Activity
- [ ] (iPhone 14 Pro+) Dynamic Island shows compact view

## 🚨 Common Issues

### "Live Activities are not enabled" in console
→ Check Settings → studyApp → Live Activities is ON

### Live Activity doesn't appear
→ Ensure `NSSupportsLiveActivities = YES` in Info.plist
→ Check iOS version is 16.1 or later
→ Rebuild the app (Cmd+Shift+K, then Cmd+B)

### Build errors mentioning ActivityKit
→ Ensure deployment target is iOS 16.1+
→ Clean build folder and rebuild

## 📱 Device Requirements

| Feature | Requirement |
|---------|------------|
| Lock Screen Widget | iOS 16.1+ (all devices) |
| Dynamic Island | iPhone 14 Pro, 14 Pro Max, 15 Pro, 15 Pro Max, or later |
| Simulator Testing | iOS 16.1+ simulator |

## ✨ What You'll See

### Lock Screen
```
┌─────────────────────────────────┐
│  📖  Mathematics                │
│      MATH101                    │
│                      15:42      │
│                      Studying   │
└─────────────────────────────────┘
```

### Dynamic Island (Compact)
```
[📖] ─── [15:42]
```

### Dynamic Island (Expanded)
```
┌───────────────────────────────┐
│  📖 MATH101        ▶️          │
│                               │
│      Mathematics              │
│        15:42                  │
│                               │
│    ⚠️ 2        ☕ 05:30       │
└───────────────────────────────┘
```

## 🎨 What Gets Displayed

- **Subject name**: "Mathematics"
- **Subject code**: "MATH101"
- **Session timer**: "15:42" (MM:SS)
- **Status**: "Studying" or "Paused"
- **Interruptions**: ⚠️ count (if > 0)
- **Break time**: ☕ duration (if > 0)

## 📚 Full Documentation

For detailed information, see: `docs/LIVE_ACTIVITY_GUIDE.md`

---

**That's it!** 🎉 Your Live Activities should now work. Start a study session to see it in action!
