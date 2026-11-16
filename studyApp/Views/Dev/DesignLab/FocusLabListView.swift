//  FocusLabListView.swift
//  studyApp
//
//  DEV ONLY — the Focus Design Lab's index. Each row opens its design full screen in
//  FocusLabHost; the lab bar there steps between designs without coming back here.

import SwiftUI

struct FocusLabListView: View {

    @State private var presentedDesign: FocusLabDesign?

    var body: some View {
        List {
            Section {
                ForEach(FocusLabDesign.allCases) { design in
                    Button {
                        presentedDesign = design
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(design.title)
                                .foregroundStyle(.primary)
                            Text(design.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("Cosmetic study and focus screens running on a mock session. Nothing here writes to SwiftData.")
            }
        }
        .navigationTitle("Focus Design Lab")
        .fullScreenCover(item: $presentedDesign) { design in
            FocusLabHost(design: design)
        }
    }
}

#Preview {
    NavigationStack {
        FocusLabListView()
    }
}
