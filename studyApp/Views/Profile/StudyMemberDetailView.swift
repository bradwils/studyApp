import SwiftUI

/// Destination pushed from the social feed when a user taps a study member.
struct StudyMemberDetailView: View {
    var memberName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Profile")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(memberName)
                    .font(.largeTitle.bold())

                Text("Recent Activity")
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    Text("• Study streak: 5 days")
                    Text("• Focus time today: 2h 15m")
                    Text("• Favorite subject: Mathematics")
                }
                .font(.body)
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Member Profile")
    }
}

#Preview {
    NavigationStack {
        StudyMemberDetailView(memberName: "Preview User")
    }
}
