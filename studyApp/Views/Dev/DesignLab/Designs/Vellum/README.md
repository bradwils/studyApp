# Vellum

Five translucent sheets of coloured tracing paper. While tracking, they fan out behind the buttons. Swiping to focus slides them up one after another into a single square tile behind the timer. As the focus block runs, they rotate apart into a rosette.

## Protocol requirements

- `slots`: keeps the standard header height, but makes the timer slot 250 pt tall so the stacked tile fits in it without touching the header.
- `backdrop`: `VellumBackdrop`. Milk background, the five sheets, and a status line pinned 40 pt below the timer's centre.
- `timer`: `FocusLabClock` in SF Rounded, 220 pt wide.
- `trackingHeader`: `VellumTrackingHeader`, the subject name or a subject menu while idle.
- `trackingBody`: `VellumTrackingPage`. Today's total and break count, then Start/Pause/Resume (and End session while paused) with the friends line, raised so that they sit on the fan.
- `focusHeader`: `VellumFocusHeader`, the subject code.
- `focusBody`: `VellumFocusPage`. Presets, Start focus block / End block / Finish, and Lock screen.
- No `chromeScheme` override.

## What drives it

- `blend`: each sheet travels on its own staggered window (starting at index × 0.09, lasting 0.64 of the swipe, smoothstepped). It goes from its fan position, size and tilt to the tile behind the timer. Between blends of 0.55 and 0.85, the timer and status text change from ink to white. The status line crossfades between its tracking and focus text. The focus controls fade in between 0.6 and 1.
- Session: `focusProgress`, smoothstepped as `bloom`, turns the stacked sheets from a slight offset to 18° per sheet. This animates over 1 s unless Reduce Motion is on. Pausing and blocks change the status text and buttons.

## Files

- `VellumDesign.swift`: the `FocusLabScreen` conformance and the `slots` override.
- `VellumBackdrop.swift`: background, sheet stack, pinned status line.
- `VellumTrackingPage.swift`: `VellumTrackingHeader` and `VellumTrackingPage`.
- `VellumFocusPage.swift`: `VellumFocusHeader` and `VellumFocusPage`.
- `VellumKit.swift`: palette, font, press style, `VellumSheet`, and `VellumLayout` (sheet geometry for any blend and bloom).

## Notes

- `VellumLayout` is built from the context in both the backdrop and the tracking body. The body's bottom spacer (`height * 0.30 - 70`) is what keeps the buttons over the fan, so change it together with the fan position in `VellumLayout.sheet`.
- Sheets draw at 46% opacity with `.multiply` blending. That is where the overlap colours come from.
- The tile is `min(timer slot height, 62% of width, 250)`.
