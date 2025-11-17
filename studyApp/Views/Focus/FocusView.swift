import SwiftUI

struct FocusView: View {
    var body: some View {
        StudyTrackingView()
            .navigationTitle("Focus")
            // .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FocusView()
    }
}
