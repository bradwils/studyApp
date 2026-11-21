# Strata

The session settles like sediment. Each stretch of study is a flat band of colour and each break a thin cream seam, stacked up from the bottom of the screen. The focus page zooms into the band being laid now, which rises as the block runs.

## Protocol requirements

- `backdrop`: `StrataBackdrop`. A Canvas of the band stack over a haze background, plus minute labels on the study bands.
- `timer`: `FocusLabClock` in DIN Alternate Bold, ink, leading-aligned at the content margin, with fixed digit cells.
- `header(for:)`: a switch over the page. Tracking is `StrataTrackingHeader`, the subject name with a subject menu while idle. Focus is `StrataFocusHeader`, the subject code.
- `content(for:)`: a switch over the page. Tracking is `StrataTrackingPage`: status ("Studying, 2 breaks" etc.), Start/Pause/Resume, End session while paused, and a footer card with today's total and the friend count. Focus is `StrataFocusPage`: status ("This layer is n minutes tall", "left of n minutes", "Layer complete"), presets, Start focus block / End block / Finish, and Lock screen. The lock state lives on the context: the page gets `isLocked` and `onLockChange` from `context.isLocked` and `context.setLocked`.
- No `slots` override and no `.focusLabChrome`.

## What drives it

- `blend` (smoothstepped) moves each band from its tracking position to its focus position. Older bands drop off below the screen and the current band fills from the bottom. Over the swipe the background takes up to a 16% tint of the current band's colour. The labels fade out over the first 40% of the swipe.
- Session: `segments` and `startedAt` set the band heights. The stack uses 58% of the screen height for whichever is longer: one hour, or 1.15 times the session so far. In focus, `focusProgress` raises the current band towards the top. Pausing opens a rest segment, so a seam becomes the current band.

## Files

- `StrataDesign.swift`: the `FocusLabScreen` conformance (a `FocusPagerScreen` that holds the mock `session`).
- `StrataBackdrop.swift`: the stack view, its Canvas and its labels.
- `StrataBands.swift`: `StrataBandLayout.bands`, the pure maths that turns segments into band rects and colours.
- `StrataTrackingPage.swift`: `StrataTrackingPage` and `StrataTrackingHeader`.
- `StrataFocusPage.swift`: `StrataFocusHeader` and `StrataFocusPage`.
- `StrataKit.swift`: palette, layout constant, font, duration formatting, press style, primary and outline button labels.

## Notes

- `StrataStackCanvas` copies everything it needs into locals before the `Canvas` closure, so the renderer touches no main-actor state if Canvas runs it off the main thread.
- Study colours cycle moss, ochre, rosewood, harbour, plum. Moss and ochre take ink labels because cream text on them is under 3:1 contrast.
- The bands and background run the full screen width. The minute labels are right-aligned to the scaffold's centred column (`contentBackdropRect.maxX`), so they stay beside the page content on a wide screen. The timer is already laid out inside the column.
- A break band is at least 3 pt tall, grown downward so that the next band up, drawn later, cannot cover it.
