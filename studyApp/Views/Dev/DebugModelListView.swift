//  DebugModelListView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Generic entry list for a
//  single SwiftData model: view every record, delete one, or delete all.

import SwiftUI
import SwiftData

struct DebugModelListView<Model: PersistentModel, RowContent: View>: View {
    let title: String
    @ViewBuilder private var rowContent: (Model) -> RowContent

    @Query private var items: [Model]
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingDeleteAllConfirmation = false

    init(title: String, @ViewBuilder rowContent: @escaping (Model) -> RowContent) {
        self.title = title
        self.rowContent = rowContent
    }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("No \(title)", systemImage: "tray")
            } else {
                ForEach(items, id: \.persistentModelID) { item in
                    rowContent(item)
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isShowingDeleteAllConfirmation = true
                } label: {
                    Label("Delete All", systemImage: "trash")
                }
                .disabled(items.isEmpty)
            }
        }
        .confirmationDialog(
            "Delete all \(items.count) \(title)?",
            isPresented: $isShowingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All \(title)", role: .destructive) {
                try? modelContext.delete(model: Model.self)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone, and may cascade-delete related records depending on this model's relationships.")
        }
    }
}
