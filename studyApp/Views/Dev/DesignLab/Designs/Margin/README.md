# Margin

A muted notebook page with one fixed margin rule. A highlighter stroke grows behind the timer; swiping to focus wipes an ink panel in from the right edge, turning the page dark.

## Protocol requirements

- `backdrop`: `MarginBackdrop`. Paper fill, the ink panel, the margin rule, and both copies of the timer.
- `timer`: `EmptyView`. The timer lives in the backdrop (see below).
- `trackingHeader`: subject name in serif with its code underneath; a subject menu while idle.
- `trackingBody`: status caption, a ledger (today's total, breaks, friends), Start/Pause/Resume, and End session while paused.
- `focusHeader`: subject code and name in paper and slate, for the ink panel.
- `focusBody`: status caption, the Length presets (hidden once a block runs), Start focus block / End block / Finish, and Lock screen.
- `chromeScheme`: `.light` below a blend of 0.5, `.dark` above, because the ink panel covers the screen by then.

## What drives it

- `blend` sets the ink panel's width (`fullWidth * blend`, anchored to the right edge). The masks for the dark margin rule and the two timer copies follow the same edge.
- Session: with a focus block, the stroke length is `focusProgress`. Without one, it fills once a minute from study time. Pausing and blocks change the captions and buttons. The stroke animates linearly over 1 s unless Reduce Motion is on.

## Files

- `MarginDesign.swift`: the `FocusLabScreen` conformance.
- `MarginBackdrop.swift`: paper, ink panel, rule, and the two masked timers.
- `MarginTimer.swift`: one timer plus its highlighter stroke, laid out in a full-size frame.
- `MarginTrackingPage.swift`: `MarginTrackingHeader` and `MarginTrackingPage`.
- `MarginFocusPage.swift`: `MarginFocusHeader` and `MarginFocusPage`.
- `MarginKit.swift`: palette, layout constants, fonts, press style, `MarginBar` and `MarginRule`.

## Notes

- The timer has to change colour exactly at the ink edge as it crosses the digits, so the backdrop draws it twice in the same full-size frame (so the copies line up exactly) and masks each copy with `MarginBar` to its side of the edge. On paper the stroke is a thick highlighter band; on ink it is a thin underline. The ink copy is hidden from VoiceOver.
- The timer is positioned from `timerBackdropRect`, so it still follows the scaffold's timer slot.
