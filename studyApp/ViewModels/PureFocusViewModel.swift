//
//  PureFocusViewModel.swift
//  studyApp
//
//  Created by brad wils on 2/1/26.

import SwiftUI
import Combine

/// Drives the Pomodoro-style mini timer inside `PureFocusView`.
/// Handles the per-second ticker, tracking whether a timer exists, and exposes progress helpers for the background animation.
class PureFocusViewModel: ObservableObject {
    
    // MARK: - Sheet Properties
    
    // @Published marks this property so SwiftUI automatically
    // updates any Views observing this model when it changes
    
    // MARK: - Timer Properties
    
    /// Total duration for the focus session in seconds (default: 25 minutes)
    
    /// Elapsed time in seconds since timer started
    @Published var elapsedTime: TimeInterval = 0
    
    @Published var currentTimerTotalDuration: TimeInterval = 5 // default 5s, change to 0 later
    
    /// Whether the timer is currently running
    @Published var timerActivelyRunning: Bool = false //no timers, initially
    
    @Published var timerActivelyExists: Bool = false //tracks if there is any timer that currently exists
    
    /// Computed progress value (0.0 to 1.0) for the gradient animation
    var timerProgress: CGFloat { //need this to track for background
        guard currentTimerTotalDuration > 0 else { return 0 }
        return CGFloat(min(elapsedTime / currentTimerTotalDuration, 1.0))
    }
    
    /// Remaining time in seconds
    var remainingTime: TimeInterval {
        max(0, currentTimerTotalDuration - elapsedTime)
    }
    
    // Timer publisher
    private var timerCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    init() {
        // Timer publisher will be created when timer starts
    }
    
    // MARK: - Timer Methods
    
    /// Starts or resumes the focus timer with the supplied duration.
    /// 
    /// The timer publishes every 0.1 seconds so the background animation stays smooth.
    func startTimer(setTimerDuration: TimeInterval) { //parse through 
        guard !timerActivelyRunning else { return }
        
        timerActivelyRunning = true
        timerActivelyExists = true
           
           // Create a timer that fires every 0.1 seconds for smooth animation
           timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
               .autoconnect() //autoconnect means that as soon as tye subscription is made
            .sink { [weak self] _ in //weak self is saying 'keep running this code, unless the object is deallocated (paused; done when we cancel the timer when pauwsing or stopping it)
                guard let self = self else { return }
                
                if self.elapsedTime < setTimerDuration {
                    self.elapsedTime += 0.1
                } else {
                    // Timer completed
                    self.stopTimer()
                    self.elapsedTime = 0 //reset value
                }
            }
    }
    
    /// Pause the timer
    /// Pauses the timer while keeping the current elapsed time so it can resume later.
    func pauseTimer() {
        timerActivelyRunning = false
        timerCancellable?.cancel() //cancels the
        timerCancellable = nil
    }
    
    /// Stop and reset the timer
    /// Stops the timer, cancels the ticker, and marks that no timer currently exists.
    func stopTimer() {
        timerActivelyRunning = false
        timerActivelyExists = false

        
        timerCancellable?.cancel()
        timerCancellable = nil
        
    }
    
    /// Reset timer to start
    ///
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        timerActivelyRunning = false
        timerActivelyExists = false

    }
    
    /// Toggle timer between running and paused
    func toggleTimer() { //needs to have 3 different functions:
        if timerActivelyRunning { //pause timer ('break')
            pauseTimer()
            
        } else { //start a new timer
            startTimer(setTimerDuration: currentTimerTotalDuration)
        }
    }
    
    /// Adjusts the stored duration and resets the timer if the new duration drops below the elapsed time.
    func setDuration(timerDurationInSeconds: TimeInterval) { //this function takes seconds
        if elapsedTime > timerDurationInSeconds {
            elapsedTime = 0
            timerActivelyRunning = false
            timerActivelyExists = false
        }
    }
}
