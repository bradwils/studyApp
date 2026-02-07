//
//  DurationPicker.swift
//  studyApp
//
//  Created on 31/1/26.
//


import SwiftUI

///What is this file?
///This file is for a duration picker. You should be able to:
/// - Input the minimum & maximum pickable minutes & hours
/// Have a used Binding which will change the value to show how long has been selected (as a timeInterval), as well as a View which
///

/// A reusable duration picker that allows selecting hours (0-8) and minutes (0-59)
struct DurationPicker: View {
    
    /// Binding to the total duration in seconds
    @Binding var duration: TimeInterval
    
    @Binding var minHours: Int
    @Binding var maxHours: Int
    @Binding var minMinutes: Int
    @Binding var maxMinutes: Int
    
    /// Maximum hours allowed (default: 8)
    
    /// Optional title text
    var title: String? = "Set Duration"
    
    var body: some View {
        VStack(spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 0) {
                // Hours picker
                Picker("Hours", selection: Binding(
                    get: { Int(duration) / 3600 },
                    set: { hours in //sets hours
                        let minutes = (Int(duration) % 3600) / 60
                        duration = TimeInterval(hours * 3600 + minutes * 60)
                    }
                )) {
                    ForEach(minHours...maxHours, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                            .foregroundColor(.white.opacity(0.8))

                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                Text("h")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 4)
                
                // Minutes picker
                Picker("Minutes", selection: Binding(
                    get: { (Int(duration) % 3600) / 60 },
                    set: { minutes in
                        let hours = Int(duration) / 3600
                        duration = TimeInterval(hours * 3600 + minutes * 60)
                    }
                )) {
                    ForEach(minMinutes ..< maxMinutes, id: \.self) { minute in
                        Text("\(minute)").tag(minute)
                            .foregroundColor(.white.opacity(0.8))

                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                Text("m")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 4)
            }
            .frame(height: 100)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var duration: TimeInterval = 25 * 60 // 25 minutes
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    DurationPicker(duration: $duration, minHours: .constant(0), maxHours: .constant(8), minMinutes: .constant(0), maxMinutes: .constant(30))
                    
                    Text("Selected: \(Int(duration / 60)) minutes")
                        .foregroundColor(.white)
                }
            }
        }
    }
    return PreviewWrapper()
}
