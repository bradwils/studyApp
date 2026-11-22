# Tape

Time as a measuring tape. A white tape slides under a fixed needle at the centre of the screen, with study time inked on it in mint. Swiping to the focus page zooms the tape out until the whole focus block fits, with a red flag at the goal.

## Protocol requirements

- `backdrop`: `TapeBackdrop`. Background, the tape (`TapeRibbon`), the needle and a status line just under the timer slot.
- `timer`: `FocusLabClock` in condensed semibold system type, capped at 88 pt.
- `header(for:)`: a switch on the page. Tracking is `TapeTrackingHeader`, subject name or a subject menu while idle, with today's total and break count underneath. Focus is `TapeFocusHeader`, the subject code in tape white.
- `content(for:)`: a switch on the page. Tracking is `TapeTrackingPage`, Start/Pause/Resume, End session while paused, the friends line, and a "Swipe left for focus" hint during a session. Focus is `TapeFocusPage`, presets, Start focus block / End block / Finish, and Lock screen. The lock state is owned by the context, so the focus page gets `context.isLocked` and `context.setLocked`.
- Chrome: the design applies `.focusLabChrome` to its backdrop, `.light` below a blend of 0.5 and `.dark` above, because the background goes from fog to slate.
- No `slots` override.

## What drives it

- `blend` changes the background from fog to slate and the timer from ink to tape white (between 0.4 and 0.7). It crossfades and recolours the status line. It also interpolates the tape's scale from 24 pt per minute to a scale that fits the focus block into half the page column (500 pt at most), and fades the flag in between 0.3 and 0.8.
- Session: time since `startedAt` positions the minute ticks, which are labelled every 5 or 15 minutes depending on zoom. Study `segments` become mint ink, cut off at the needle, so breaks leave gaps. `focusGoal` places the flag. With no block, `focusDuration` sets the zoom.

## Files

- `TapeDesign.swift`: the `FocusLabScreen` conformance (a `FocusPagerScreen` that holds the mock `session`).
- `TapeBackdrop.swift`: background, tape and needle placement, and the private status line.
- `TapeRibbon.swift`: the tape view, its two Canvases (tape with ticks and ink, flag) and `TapeNeedle`.
- `TapeScale.swift`: all the tape maths as plain values (tick positions, ink rects, flag x, zoom).
- `TapeTrackingPage.swift`: `TapeTrackingHeader` and `TapeTrackingPage`.
- `TapeFocusPage.swift`: `TapeFocusHeader` and `TapeFocusPage`.
- `TapeKit.swift`: palette, layout offsets below the timer slot, font, press style, formatting.

## Notes

- Both content views start with a clear spacer of `TapeLayout.bodyTopInset` (gap plus tape height) so their controls sit below the tape, which is drawn in the backdrop.
- The ribbon redraws on `TimelineView(.animation)` at 15 fps so the tape slides smoothly. Under Reduce Motion it drops to a 1 s periodic tick.
- The tape, needle and status line stay centred and the tape runs the full width of the screen. Only the focus zoom uses the column width, so on an iPad the flag lands over the controls instead of near the screen edge, and the zoom matches an iPhone.
- The Canvases copy their values into locals before drawing. `TapeScale.ticks` is capped at 400 ticks.
