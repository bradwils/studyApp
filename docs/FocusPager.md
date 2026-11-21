# Designing a Focus pager screen

Regular study tracking and Pure Focus are two pages of one session. Each page supplies a header and lower content. The scaffold owns the pinned timer position between them.

```text
            Tracking       Pure Focus
          ┌──────────────┬──────────────┐
Safe top  │ Study header │ Focus header │  swipe
          ├──────────────┴──────────────┤
          │       Pinned timer          │  stays put
          ├──────────────┬──────────────┤
          │ Main study   │ Set a focus  │  swipe
          │ controls +   │ duration and │
          │ theme content│ manage lock  │
          └──────────────┴──────────────┘
```

One page fills the viewport at rest. Tracking holds the study session actions and has room for a design’s own content. Pure Focus lets someone set a timed focus block within that same study session. Idle offers Tracking alone. Running and paused offer both pages. The lock disables swiping.

## Layout

- **Width.** The pager and backdrop span the viewport. Center readable content and the timer in a column capped at 500 pt. Live page insets are 16 pt for Tracking and 24 pt for Pure Focus. Lab designs can supply their own insets.
- **Height.** The standard header occupies the first 96 pt of the safe area. Both pages reserve the same timer gap below it, based on 120 pt scaled with Dynamic Type. Use the scaffold’s slots if a design needs a different band size so the timer and both pages stay aligned.
- **Flexible content.** Let text wrap and controls size to their contents. Prefer padding and min/max bounds over fixed content frames. Keep artwork proportional to the available space. Use the context’s timer and content rectangles to align decorative layers with the readable column.
- **Landscape.** The app supports portrait on iPhone and both orientations on iPad. Check iPad landscape, a narrow iPad window, and larger text. When vertical space runs short, reflow the lower controls or let them scroll vertically so the primary action stays reachable.

## What to change

- **Edit an existing page.** Start with its header and lower content in [FocusSessionContent](../studyApp/Views/Focus/FocusSessionContent.swift) or the lab design’s corresponding views. Typography, illustration, page content, and transitions can vary freely within the shared slots.
- **Add a lab theme.** Adopt [FocusLabScreen](../studyApp/Views/Dev/DesignLab/Kit/FocusLabScreen.swift), supply the visual layers and both page bodies, and register the design in [FocusLabDesign](../studyApp/Views/Dev/DesignLab/FocusLabDesign.swift). The host supplies the mock session and pager state.
- **Add a page type.** Add a case to [FocusPage](../studyApp/ViewModels/Focus/FocusPage.swift), choose its phases, order, and background in [FocusPagePolicy](../studyApp/ViewModels/Focus/FocusPagePolicy.swift), and update the live and lab header/content switches plus any per-page padding. Update [pager unit tests](../studyAppTests/FocusPagerTests.swift) for availability and fallback when the page disappears.

Use [FocusPagerScaffold](../studyApp/Views/Focus/Pager/FocusPagerScaffold.swift) for navigation, lock state, and geometry. Read swipe weights in the layer that animates so a decorative transition can follow the drag without rebuilding unrelated content. Controls belong in the page layers where they receive touches.
