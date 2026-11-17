# Stars

A night sky you fill in. Every five minutes of study lights four more stars. On the focus page the sky turns around the timer, and an eight-star figure is drawn line by line as the block runs. Pausing lets dawn in.

## Protocol requirements

- `backdrop`: `StarsBackdrop`. A midnight-to-indigo gradient, a dawn layer, the star field, the figure, and a status line 44 pt below the timer's centre.
- `timer`: `FocusLabClock` in Gill Sans Light at a fixed size (already scaled by `@ScaledMetric`), with fixed digit cells.
- `trackingHeader`: subject name; a subject menu while idle.
- `trackingBody`: an empty 40 pt status row (the status is in the backdrop), Start/Pause/Resume, End session while paused, and a footer with today's total and friends.
- `focusHeader`: subject code.
- `focusBody`: the same empty status row, with the controls (presets, outline Start/End/Finish pill, Lock screen) pushed to the bottom so the figure around the timer stays clear.
- No `slots` override and no `.focusLabChrome`. The design is dark throughout, set by `FocusLabDesign.colorScheme`.

## What drives it

- `blend` (smoothstepped) rotates the star field around the timer's centre by up to 0.21 rad and spreads it by up to 16%. It fades the figure's lines in to 80% and brightens its anchor stars from 25% to full. It also crossfades the status line.
- Session: study time sets how many stars are lit (14 to start, plus 4 per five minutes, up to 90). `focusProgress` sets how much of the figure's closed loop is drawn. Pausing fades the dawn layer in and dims the field to 30%, both over 0.6 s.

## Files

- `StarsDesign.swift`: the `FocusLabScreen` conformance (a `FocusPagerScreen` that holds the mock `session`).
- `StarsBackdrop.swift`: sky, dawn, the private sky view with its two Canvases, and the status line.
- `StarsField.swift`: `StarsField` (star positions, lit count, turn) and `StarsFigure` (anchors and partial segments) as plain values.
- `StarsTrackingPage.swift`: `StarsTrackingHeader` and `StarsTrackingPage`.
- `StarsFocusPage.swift`: `StarsFocusHeader` and `StarsFocusPage`.
- `StarsKit.swift`: palette, layout constants, fonts, press style, `StarsPill`, formatting.

## Notes

- The maths types are `nonisolated`, and the Canvases copy their inputs into locals, so the renderer touches no main-actor state.
- Star positions come from a deterministic sine hash, so the sky is the same on every launch.
- The figure's radii (124 to 168 pt around the timer's centre) are fixed points, not scaled to screen width. The timer's centre is the column's centre, so the figure and the status line stay centred on a wide screen. The sky and the star field span the whole screen and turn around that same point.
- `StarsLayout.statusRowHeight` in the bodies and `StarsLayout.statusOffset` in the backdrop must stay in step.
