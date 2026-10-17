//
//  formattedTimeInterval.swift
//  studyApp
//
//  Created by brad wils on 20/7/26.
//

import SwiftUI

//Send a TimeInterval, and have it returned as a formatted string. Allows for both pos/neg intervals, which are converted to always be positive.
public func formattedTimeInterval(_ interval: TimeInterval) -> String {
	var int = interval
	if (int < 0) { int = -int}
    let totalSeconds = Int(int.rounded(.down))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return hours > 0
        ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%02d:%02d", minutes, seconds)
}


#Preview {
	HStack {
		Text(formattedTimeInterval(6))
	}
}
