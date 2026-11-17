# Daylight

A study day as the sun crossing the sky. Both pages share one sun. While tracking it is a small marker on the day's arc. On the focus page it becomes a large disc that rises from the horizon towards the timer as the block runs.

## Protocol requirements

- `backdrop`: `DaylightBackdrop`. Sky gradient, the day's arc, the sun (halo and disc) and the ground hill.
- `timer`: `FocusLabClock` in Avenir Next Medium, plum, with fixed digit cells because Avenir has no tabular figures.
- `trackingHeader`: subject name; a subject menu while idle.
- `trackingBody`: status line ("x of 4 h today", "On a break", "Saved ..."), Start/Pause/Resume pill, End session outline pill while paused, friends line at the bottom. Light haptic on every phase change.
- `focusHeader`: subject code.
- `focusBody`: status line under the timer. The controls (presets, primary pill, Lock screen) are pushed down by `controlsOffset` so that they sit on the ground.
- No `slots` or `chromeScheme` override.

## What drives it

- `blend`: the sky moves from noon colours to the focus palette. The arc fades out over the first half of the swipe. The sun moves from its arc position to the centre and grows from 22 pt to 168 pt (both smoothstepped). The halo fades in, and the ground slides up from below the screen.
- Session: `day` is today's total over 4 hours, capped at 1. It sets the sun's place on the arc and how much of the arc is gold. `focusProgress` lifts the focus sun from the horizon to the timer's centre and shifts the focus sky from dawn to noon. Both animate over 1 s unless Reduce Motion is on. Pausing only changes text and buttons.

## Files

- `DaylightDesign.swift`: the `FocusLabScreen` conformance.
- `DaylightBackdrop.swift`: `DaylightBackdrop` (ticks once a second) and the private `DaylightScene` that draws it.
- `DaylightTrackingPage.swift`: `DaylightTrackingPage` and `DaylightTrackingHeader`.
- `DaylightFocusPage.swift`: `DaylightFocusPage` and `DaylightFocusHeader`.
- `DaylightGeometry.swift`: every position shared by the backdrop and the focus page (arc, sun, horizon, ground).
- `DaylightKit.swift`: palette, fonts, duration formatting, press style, `DaylightPill`.

## Notes

- `DaylightGeometry` is built from the same `FocusLabContext` in both the backdrop and the focus body, so the focus controls land on the drawn ground. It works in page coordinates; anything it returns for drawing goes through `toBackdrop`.
- The horizon is at 60% of the safe height. The arc's apex sits 20 pt above the timer slot.
- This folder keeps the name `DaylightGeometry` for its maths file, as Strata, Tape and Stars name theirs after what they compute.
