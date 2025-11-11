import SwiftUI

struct ModesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Modes")
                .font(.title.bold())
            Text("Switch between different study modes and presets.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Modes")
    }
}

#Preview {
    NavigationStack {
        ModesView()
    }
}
