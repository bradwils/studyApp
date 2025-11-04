import SwiftUI

struct FocusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Mode")
                .font(.title.bold())
            Text("Configure your focus sessions and track progress.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Focus")
    }
}

#Preview {
    NavigationStack {
        FocusView()
    }
}
