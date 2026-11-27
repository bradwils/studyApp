import SwiftUI
import SwiftData

struct PlacesEditor: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PlacesEditorVM()

    @Query(sort: \PlaceOption.sortOrder) private var places: [PlaceOption]

    var body: some View {
        Form {
            Section {
                ForEach(places) { place in
                    Toggle(isOn: showsInPicker(place)) {
                        Label(place.name, systemImage: place.systemImage)
                    }
                    .deleteDisabled(place.isBuiltIn)
                    .accessibilityIdentifier("placeRow_\(place.name)")
                }
                .onDelete { offsets in
                    offsets.forEach { vm.removePlace(places[$0], context: modelContext) }
                }
            } header: {
                Text("Shown in picker")
            } footer: {
                Text("Built-in places can be hidden but not deleted.")
            }

            Section("Add a place") {
                HStack {
                    // A pending autocorrection would rewrite the field after addPlace clears it.
                    TextField("Place name", text: $vm.newPlaceName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit { vm.addPlace(context: modelContext) }
                        .accessibilityIdentifier("placeNameField")

                    Button("Add") { vm.addPlace(context: modelContext) }
                        .disabled(!vm.canAddPlace)
                        .accessibilityIdentifier("addPlaceButton")
                }
            }
        }
        .navigationTitle("Places")
    }

    private func showsInPicker(_ place: PlaceOption) -> Binding<Bool> {
        Binding(
            get: { place.showsInPicker },
            set: { vm.setShowsInPicker($0, for: place, context: modelContext) }
        )
    }
}

#Preview {
    NavigationStack {
        PlacesEditor()
    }
    .modelContainer(for: PlaceOption.self, inMemory: true)
}
