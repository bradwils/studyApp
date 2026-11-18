//  DebugTagListView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Create, recolor and delete
//  global Tags.

import SwiftUI
import SwiftData

struct DebugTagListView: View {
    @Query(sort: \Tag.key) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TagDebugVM()

    var body: some View {
        List {
            Section("New tag") {
                HStack {
                    TextField("Name", text: $vm.newName)
                        .textInputAutocapitalization(.never)
                        .onSubmit(add)
                    colorMenu(selection: $vm.newColor)
                    Button("Add", action: add)
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.canAdd)
                }
            }
            Section("Tags (\(tags.count))") {
                if tags.isEmpty {
                    ContentUnavailableView("No Tags", systemImage: "tag")
                }
                ForEach(tags) { tag in
                    HStack {
                        Text(tag.key)
                        Spacer()
                        colorMenu(selection: Binding(get: { tag.color }, set: { tag.color = $0 }))
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            vm.delete(tag, context: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Tags")
    }

    private func add() {
        vm.addTag(context: modelContext)
    }

    private func colorMenu(selection: Binding<TagColor>) -> some View {
        Menu {
            Picker("Color", selection: selection) {
                ForEach(TagColor.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
        } label: {
            Image(systemName: "circle.fill").foregroundStyle(selection.wrappedValue.swatch)
        }
    }
}

private extension TagColor {
    var swatch: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .mango: .yellow
        case .hazel: .brown
        case .white: .white
        case .gray: .gray
        }
    }
}
