//
//  FormattedElapsedTime.swift
//  studyApp
//
//  Created by brad wils on 20/7/26.
//

import SwiftUI

public func formattedElapsed(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval.rounded(.down))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return hours > 0
        ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%02d:%02d", minutes, seconds)
}
