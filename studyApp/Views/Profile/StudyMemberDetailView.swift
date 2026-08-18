import SwiftUI

/// Destination pushed from the social feed when a user taps a study member.
struct StudyMemberDetailView: View {
    var memberName: String

    var body: some View {
        List {
            Section("Profile") {
                Text(memberName)
                    .font(.title2.bold())
            }

            Section("Recent Activity") {
                LabeledContent("Study streak", value: "5 days")
                LabeledContent("Focus time today", value: "2h 15m")
                LabeledContent("Favorite subject", value: "Mathematics")
            }
        }
        .navigationTitle("Member Profile")
    }
}

#Preview {
    NavigationStack {
        StudyMemberDetailView(memberName: "Preview User")
    }
}
