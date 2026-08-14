import SwiftUI

struct GroupsView: View {
    var body: some View {
        ContentUnavailableView(
            "Study Groups",
            systemImage: "person.3",
            description: Text("Create and manage collaborative study groups.")
        )
        .navigationTitle("Groups")
    }
}

#Preview {
    NavigationStack {
        GroupsView()
    }
}
