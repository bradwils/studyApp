//  DashboardHeader.swift
//  studyApp

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
                                    .padding(.leading, 8)
                                Image(systemName: "wave.3.forward")
                                    .foregroundColor(.green)
                                
                            }
                        } else {
                            Text("No friends studying")
                                .padding(.leading, 8)
                            
                            
                        }
                        
                    }
                    
                    
                    Spacer()
                    
                    
                    Menu {
                        NavigationLink("Settings") { SettingsView() }
                        NavigationLink("Profile") { StudyMemberDetailView(memberName: "Preview User 0") }
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            ZStack {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .glassEffect(in: .rect(cornerRadius: 28))
                        .padding(-15)
                        .frame(maxHeight: 50)

                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .glassEffect(in: .rect(cornerRadius: 28))
                        .padding(-15)
                        .frame(height: 50)
                }
                
                HStack(spacing: 20) {
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("Total: \(totalDailyTime)")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(currentSessionTime)
                            .font(.title2.weight(.semibold))
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
            .padding(15)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    DashboardHeader(currentSessionTime: "One", currentSubject: "CurrentSubj", streakCount: 4, totalDailyTime: "100")
}
