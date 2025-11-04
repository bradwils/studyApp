import SwiftUI

struct GroupsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Groups")
                .font(.title.bold())
            Text("Create and manage collaborative study groups.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Groups")
    }
}

#Preview {
    NavigationStack {
        GroupsView()
    }
}
