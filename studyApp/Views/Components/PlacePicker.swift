import SwiftUI
import SwiftData

struct PlacePicker: View {
    let vm: StudyTrackingViewModel

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<PlaceOption> { $0.showsInPicker }, sort: \PlaceOption.sortOrder)
    private var places: [PlaceOption]

    @ScaledMetric(relativeTo: .caption) private var chipVerticalPadding: CGFloat = 8

    private var selectedPlace: PlaceOption? {
        places.first { $0.name == vm.selectedPlaceName }
    }

    var body: some View {
        Menu {
            Picker("Place", selection: selection) {
                Text("No place").tag(String?.none)
                ForEach(places) { place in
                    Label(place.name, systemImage: place.systemImage)
                        .tag(Optional(place.name))
                }
                // A hidden or deleted place stays listed while it's still the selection.
                if let name = vm.selectedPlaceName, selectedPlace == nil {
                    Label(name, systemImage: "mappin.and.ellipse").tag(Optional(name))
                }
            }
        } label: {
            Label(vm.selectedPlaceName ?? "Add place", systemImage: selectedPlace?.systemImage ?? "mappin.and.ellipse")
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, chipVerticalPadding)
                .glassEffect()
        }
        .accessibilityIdentifier("placePickerButton")
        .task { vm.restoreLastPlace(context: modelContext) }
    }

    private var selection: Binding<String?> {
        Binding(
            get: { vm.selectedPlaceName },
            set: { name in
                guard name != vm.selectedPlaceName else { return }
                vm.selectPlace(places.first { $0.name == name }, context: modelContext)
            }
        )
    }
}
