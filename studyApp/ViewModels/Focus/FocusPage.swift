// Page identity stays stable when the available page list changes.
enum FocusPage: Hashable, Identifiable {
    case tracking
    case focus

    var id: Self { self }
}
