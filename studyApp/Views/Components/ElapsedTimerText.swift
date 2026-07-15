//
//  ElapsedTimerText.swift
//  studyApp
//
//  Created by brad wils on 14/7/26.
//

import SwiftUI


//Takes two time intervals, and returns a ticking timer formatted as MM:SS / HH:MM:SS.
struct ElapsedTimerText: View {
    
    var interval: TimeInterval
    
    var totalRuntime: Int

    
    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { _ in
            Text(formattedElapsed(interval))
                .contentTransition(.numericText())
                .animation(.linear, value: Int(totalRuntime))
        }
    }
    
    
    
    
    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
