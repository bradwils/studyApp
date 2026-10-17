//
//  CountdownTimerText.swift
//  studyApp
//
//  Created by brad wils on 17/9/26.
//

import SwiftUI


struct CountdownTimerText: View {
	var distanceInFuture: Date

	// Fixed once per view identity so the countdown range's lower bound doesn't drift on every re-render.
	@State private var start = Date.now

	var body: some View {
		Text(.currentDate, format: .timer(countingDownIn: start..<distanceInFuture))
			.contentTransition(.numericText(countsDown: true))
	}

	mutating func addTimeInterval(_ amount: TimeInterval) {
		distanceInFuture = distanceInFuture.addingTimeInterval(amount)
	}
}

#Preview {
	@Previewable @State var d: Date = Date.now.addingTimeInterval(-4)

	CountdownTimerText(distanceInFuture: d)
}
 
