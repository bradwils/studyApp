TODO / Deferred items from code review feedback
================================================

1. [DEFERRED] StudyItemCard — choose a card variant
   Three visual styles are shown in the friends list (one per entry) so you can compare them:
     - Variant A: accentBar  (left coloured bar + initials circle + subject code)
     - Variant B: bubbleCard (large avatar ring + subject tag pill)
     - Variant C: compactRow (tiny status dot + single-line compact layout)
   Once you pick one, remove the others and apply the chosen style to all cards.
   — Raised in review comment #2875637142

2. [DEFERRED] CustomBottomSheet — glass effect background
   Currently using .regularMaterial as a placeholder.
   Manually figure out how to replicate a true glassEffect on a custom-shaped view,
   since .glassEffect() cannot yet be applied to UnevenRoundedRectangle in the background modifier.
   — Raised in review comment #2875640625

3. [DEFERRED] Focus slider reset — verify timing on device
   The slider resets to 0 via .onAppear on PureFocusView (fires as the view appears,
   i.e., while StudyTrackingView is sliding off-screen). Confirm this feels right on device.
   — Raised in review comment #2875637142

4. [TODO] DurationPicker binding in PureFocusView
   Make the picker bind correctly to vm.currentTimerTotalDuration.
   — Existing note in PureFocusView.swift

5. [TODO] Tab bar snap on PureFocusView navigation
   Tab bar is now hidden in PureFocusView (.toolbar(.hidden, for: .tabBar)).
   Monitor whether the layout jump on back-navigation reappears; if so, revisit
   the .ignoresSafeArea or padding strategy on StudyTrackingView.
   — Raised in review comment #2875646251
