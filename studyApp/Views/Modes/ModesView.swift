import SwiftUI

struct ModesView: View {
    var body: some View {
        ContentUnavailableView(
            "Modes",
            systemImage: "square.grid.2x2",
            description: Text("Switch between different study modes and presets.")
        )
        .navigationTitle("Modes")
    }
}

#Preview {
    NavigationStack {
        ModesView()
    }
}
