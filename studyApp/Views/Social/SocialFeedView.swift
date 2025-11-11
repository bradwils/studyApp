import SwiftUI

struct SocialView: View {
    @State private var items: [ListItem] = [
        ListItem(name: "A", subject: "Math", subjectCode: "MATH", isLocked: false, timer: "00:10", photo: "person.crop.square", dailyTotalTime: "4:00"),
        
        ListItem(name: "Bob", subject: "Physics", subjectCode: "PHYS", isLocked: true, timer: "00:20", photo: "person.crop.square.fill", dailyTotalTime: "5:00"),
        
        ListItem(name: "Carol", subject: "Chemistry", subjectCode: "CHEM", isLocked: false, timer: "00:30", photo: "person.crop.square", dailyTotalTime: "6:00"),
        
        ListItem(name: "Dave", subject: "Biology", subjectCode: "BIO", isLocked: true, timer: "00:40", photo: "person.crop.square.fill", dailyTotalTime: "7:00"),
        
        ListItem(name: "Earl", subject: "English", subjectCode: "ENG", isLocked: true, timer: "00:50", photo: "person.crop.square.fill", dailyTotalTime: "8:00"),
        
        ListItem(name: "A", subject: "Math", subjectCode: "MATH", isLocked: false, timer: "00:10", photo: "person.crop.square", dailyTotalTime: "4:00"),
        
        ListItem(name: "Anthony", subject: "Math", subjectCode: "MATH", isLocked: false, timer: "00:10", photo: "person.crop.square", dailyTotalTime: "4:00")

        
    ]

    // Add state for current study session
    @State private var currentSessionTime = "00:00"
    @State private var currentSubject = "Math"
    @State private var streakCount = 5
    @State private var totalDailyTime = "02:34"

    var body: some View {
        ZStack(alignment: .top) {
            RadialGradient(
                colors: [Color.yellow.opacity(0.8), Color.white.opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            .frame(height: 300)

                // Linear gradient overlaid on top
            LinearGradient(
                colors: [Color.white.opacity(0.5), Color.pink.opacity(0.5), Color.blue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)

            LinearGradient(
                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            .frame(height: 300)

            LinearGradient(
                colors: [Color.white.opacity(0), Color.white.opacity(1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)

            ScrollView {
                VStack(spacing: 16) {
                    DashboardHeader(
                        currentSessionTime: currentSessionTime,
                        currentSubject: currentSubject,
                        streakCount: streakCount,
                        totalDailyTime: totalDailyTime
                    )
                    .padding(.horizontal, 10)

                        LazyVStack(spacing: 5) {
                            ForEach(items) { item in
                                NavigationLink {
                                    StudyMemberDetailView(memberName: item.name)
                                } label: {
                                    StudyItemCard(item: item)
                                        .padding(.horizontal, 15)
                                        .shadow(radius: 20)
                                }
                                .buttonStyle(.plain)
                                .padding(.bottom, 5)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .scrollIndicators(.hidden)

        }
        .navigationBarTitle("Social", displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)

    }
}

#Preview {
    SocialView()
}
