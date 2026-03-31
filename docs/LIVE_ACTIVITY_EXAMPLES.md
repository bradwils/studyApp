# Live Activity Visual Examples

## Lock Screen Widget

When you lock your iPhone while studying, you'll see:

```
╔═══════════════════════════════════════════════════╗
║                                                   ║
║    📖                                             ║
║                                                   ║
║    Mathematics                          15:42    ║
║    MATH101                              Studying ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

### When Paused

```
╔═══════════════════════════════════════════════════╗
║                                                   ║
║    📖  ⏸️                                          ║
║                                                   ║
║    Mathematics                          23:15    ║
║    MATH101                              Paused   ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

### With Interruptions and Breaks

```
╔═══════════════════════════════════════════════════╗
║                                                   ║
║    📖                                             ║
║                                                   ║
║    Physics                              45:30    ║
║    PHYS201                              Studying ║
║                                                   ║
║    ⚠️  3        ☕ 08:45                         ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

## Dynamic Island (iPhone 14 Pro and later)

### Compact View (most of the time)

```
[📖] ━━━━━━━━━━━━━━━━━━━━ [15:42]
 └─ Subject icon        └─ Timer
```

### Compact View (when paused)

```
[📖] ━━━━━━━━━━━━━━━━━━━━ [23:15]
 └─ Subject icon        └─ Timer (orange)
```

### Expanded View (when you long-press the Dynamic Island)

```
┌─────────────────────────────────────────┐
│                                         │
│  📖 MATH101                   ▶️         │
│                                         │
│           Mathematics                   │
│                                         │
│              15:42                      │
│         (large, bold timer)             │
│                                         │
│      ⚠️  2          ☕ 05:30            │
│   interruptions      break time         │
│                                         │
└─────────────────────────────────────────┘
```

### Minimal View (when multiple Live Activities are active)

```
[📖]
 └─ Just the book icon
```

## Color Scheme

- **Blue**: Active session (book icon, timer when studying)
- **Orange**: Paused state (pause icon, timer when paused)
- **Green**: "Studying" status text
- **Gray/Secondary**: Break time, subject code

## Animation & Updates

- **Timer**: Updates every second (smooth counting)
- **Status**: Changes immediately when you pause/resume
- **Interruptions**: Updates immediately when added
- **Appearance**: Fades in when session starts
- **Disappearance**: Fades out when session ends

## Examples for Different Subjects

### Mathematics
```
╔═══════════════════════════════════════════════════╗
║    📖   Mathematics                       15:42   ║
║         MATH101                           Studying║
╚═══════════════════════════════════════════════════╝
```

### Computer Science
```
╔═══════════════════════════════════════════════════╗
║    📖   Computer Science                  02:30   ║
║         CS101                             Studying║
╚═══════════════════════════════════════════════════╝
```

### Long Study Session
```
╔═══════════════════════════════════════════════════╗
║    📖   Biology                         1:23:45   ║
║         BIO301                           Studying ║
║         ⚠️  5        ☕ 15:20                     ║
╚═══════════════════════════════════════════════════╝
```

## What the User Sees - Step by Step

### Step 1: Start Studying
```
1. Open app
2. Select subject: "Mathematics"
3. Tap "Start" button
   → Live Activity appears on Lock Screen
```

### Step 2: Lock Phone
```
1. Press side button to lock iPhone
2. See Live Activity on Lock Screen:
   ╔═══════════════════════════════════════════════╗
   ║    📖   Mathematics                   00:05   ║
   ║         MATH101                       Studying║
   ╚═══════════════════════════════════════════════╝
```

### Step 3: Timer Updates
```
After 1 second:
   ╔═══════════════════════════════════════════════╗
   ║    📖   Mathematics                   00:06   ║
   ║         MATH101                       Studying║
   ╚═══════════════════════════════════════════════╝

After 2 seconds:
   ╔═══════════════════════════════════════════════╗
   ║    📖   Mathematics                   00:07   ║
   ║         MATH101                       Studying║
   ╚═══════════════════════════════════════════════╝
```

### Step 4: Pause (in app)
```
1. Open app
2. Tap "Pause" button
3. Lock phone again
4. See paused state:
   ╔═══════════════════════════════════════════════╗
   ║    📖  ⏸️  Mathematics                15:42   ║
   ║           MATH101                     Paused  ║
   ╚═══════════════════════════════════════════════╝
```

### Step 5: End Session (in app)
```
1. Open app
2. Tap "End" button
   → Live Activity disappears from Lock Screen
```

## Dynamic Island States

### When studying:
```
[📖] ━━━ [15:42]  (blue timer, green icon)
```

### When paused:
```
[📖] ━━━ [15:42]  (orange timer, orange pause icon)
```

### Long press to expand:
```
Full details with subject name, timer, metrics
```

## Notifications Area

If you pull down your Lock Screen notification center, you'll see:

```
┌───────────────────────────────────────────┐
│  📖 studyApp                              │
│                                           │
│  Mathematics                      15:42   │
│  MATH101                         Studying │
└───────────────────────────────────────────┘
```

## Summary

The Live Activity provides **at-a-glance information** without needing to:
- Unlock your phone
- Open the app
- Navigate to the study screen

Just lock your phone and glance at the Lock Screen to see:
- What you're studying
- How long you've been studying
- Whether you're actively studying or paused

---

**Simple, functional, and always visible when you need it!**
