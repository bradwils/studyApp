import SwiftUI

struct GroupsView: View {
    var body: some View {
        ZStack {
            ScreenBackground()
            ContentUnavailableView {
                Label("Study Groups", systemImage: "person.3")
            } description: {
                Text("Create and manage collaborative study groups with friends.")
            } actions: {
                VStack(spacing: DS.Space.s) {
                    Button("Create a Group", systemImage: "plus") {}
                        .buttonStyle(.glass)
                        .disabled(true)
                }
            }
        }
        .navigationTitle("Groups")
    }
}

#Preview {
    NavigationStack {
        GroupsView()
    }
}
