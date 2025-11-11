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
    var onlineFriends = 2 //placeholder

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 30) {
                
                
                

                HStack {
                    VStack {
                        Text("Your Friends")
                            .bold()
                            .italic()
                            .font(.system(size: 36))
                        
                        
                        if onlineFriends > 0 {
                            HStack {
                                Text("\(onlineFriends) Friends studying ")
                                    .foregroundColor(.green)
//                                    .padding(.leading, 8)
                                Image(systemName: "wave.3.forward") //doesnt work
                                    .foregroundColor(.green)
                                
                            }
                        } else {
                            Text("No friends studying")
                                .padding(.leading, 8)
                            
                            
                        }
                        
                    }
                    
                    
                    Spacer()
                    
                    
                    Menu { // System menu; label can be re-laid out during presentation/dismissal
                        NavigationLink("Settings") { SettingsView() }
                        NavigationLink("Profile") { StudyMemberDetailView(memberName: "Preview User 0") }
                    } label: { // Make the label's size and hit area deterministic
                        Image(systemName: "person.crop.circle.fill")
                            .resizable() // Allow symbol to scale predictably
                            .scaledToFit() // Preserve aspect ratio so it stays centered without clipping
                            .frame(width: 44, height: 44) // Icon size smaller than container; creates internal padding instead of external
                            .foregroundStyle(.primary) // Visual style only; does not affect layout
                    }
                    .buttonStyle(.plain) // Prevents default button padding/animation from shifting layout
                }
            }
            
            ZStack {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .glassEffect(in: .rect(cornerRadius: 28))
                        .padding(-15)
//                        .frame(height: 50)
                        .frame(maxHeight: 50)

                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .glassEffect(in: .rect(cornerRadius: 28))
                        .padding(-15)
                        .frame(height: 50)
                }
                
                HStack(spacing: 20) {
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("Total: \(totalDailyTime)") //align this centrally
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(currentSessionTime)
                            .font(.title2.weight(.semibold))
//                            .foregroundStyle(Color.primary)

                        
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
            .padding(15) //just for the personal study card, messy but redo later.
        }
        .padding(.horizontal, 20) //for all elements
    }
}

#Preview {
    DashboardHeader(currentSessionTime: "One", currentSubject: "CurrentSubj", streakCount: 4, totalDailyTime: "100")
}
