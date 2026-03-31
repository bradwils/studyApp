import Foundation
import SwiftUI
import Combine

/// ViewModel powering the Social feed.
/// Holds the feed items and dashboard summary so the view stays declarative.
final class SocialFeedViewModel: ObservableObject {
    static let sampleItems: [SocialFeedItem] = [
        SocialFeedItem(name: "A", subject: "Math", subjectCode: "MATH", isLocked: false, timer: "00:10", photo: "person.crop.square", dailyTotalTime: "4:00"),
        SocialFeedItem(name: "Bob", subject: "Physics", subjectCode: "PHYS", isLocked: true, timer: "00:20", photo: "person.crop.square.fill", dailyTotalTime: "5:00"),
        SocialFeedItem(name: "Carol", subject: "Chemistry", subjectCode: "CHEM", isLocked: false, timer: "00:30", photo: "person.crop.square", dailyTotalTime: "6:00"),
        SocialFeedItem(name: "Dave", subject: "Biology", subjectCode: "BIO", isLocked: true, timer: "00:40", photo: "person.crop.square.fill", dailyTotalTime: "7:00"),
        SocialFeedItem(name: "Earl", subject: "English", subjectCode: "ENG", isLocked: true, timer: "00:50", photo: "person.crop.square.fill", dailyTotalTime: "8:00"),
        SocialFeedItem(name: "Anthony", subject: "Computer Science", subjectCode: "CS101", isLocked: false, timer: "00:15", photo: "person.crop.square", dailyTotalTime: "3:20")
    ]

    @Published var items: [SocialFeedItem]
    @Published var currentSessionTime: String
    @Published var currentSubject: String
    @Published var streakCount: Int
    @Published var totalDailyTime: String

    init(
        items: [SocialFeedItem] = SocialFeedViewModel.sampleItems,
        currentSessionTime: String = "00:00",
        currentSubject: String = "Math",
        streakCount: Int = 5,
        totalDailyTime: String = "02:34"
    ) {
        self.items = items
        self.currentSessionTime = currentSessionTime
        self.currentSubject = currentSubject
        self.streakCount = streakCount
        self.totalDailyTime = totalDailyTime
    }
}
