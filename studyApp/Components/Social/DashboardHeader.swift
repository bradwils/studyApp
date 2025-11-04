//  DashboardHeader.swift
//  first
//
//  Created by brad wils on 20/3/25.

import SwiftUI

/// Summary banner reused across the social feed and related dashboards.
struct DashboardHeader: View {
    var currentSessionTime: String

    var currentSubject: String
    var streakCount: Int
    var totalDailyTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 30) {
                Text("Your Friends")
                    .bold()
                    .italic()
                    .font(.system(size: 36))
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("Temp")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.blue.opacity(0.9))
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                }
            }
            
            ZStack {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .glassEffect(in: .rect(cornerRadius: 28))
                        .padding(-20)
                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                }
                
                HStack(spacing: 20) {
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("Total: \(totalDailyTime)") //align this centrally
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(currentSessionTime)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.primary)

                        
                    }
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 1, height: 48)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subject")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(currentSubject)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.orange)
                        Text("\(streakCount)")
                            .font(.headline)
                            .foregroundStyle(Color.orange)
                    }
                }
            }
            .padding(20)
        }
    }
}
