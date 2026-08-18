//
//  ElapsedTimerText.swift
//  studyApp
//
//  Created by brad wils on 14/7/26.
//

import SwiftUI


struct ElapsedTimerText: View {
    /// Anchor point in time (session start or pause timestamp). The timer always measures elapsed time from this moment.
    var anchor: Date

    var body: some View {
        /// Grid schedule anchored to `anchor` ensures ticks align with integer-second boundaries of the elapsed time.
        /// Without this, a `from: .now` anchor would drift every render, falling out of phase with actual second transitions.
        TimelineView(.periodic(from: anchor, by: 1)) { context in
            /// `context.date` is the exact tick time (not "now at render time"), so elapsed time is deterministic.
            let elapsed = context.date.timeIntervalSince(anchor)

            Text(formattedElapsed(elapsed))
                .contentTransition(.numericText())
                /// Animation must track the same elapsed value; if it tracks a different formula, the numeric transition
                /// fires at the wrong moment — e.g., animating on `anchor.timeIntervalSinceNow` (negative) while displaying
                /// positive elapsed time causes misalignment.
                .animation(.linear, value: Int(elapsed)) //track for when formatted text changes (rounds to seconds, instead of every 1/1000s from TimeInterval
        }
    }
    
    
    
    
}
