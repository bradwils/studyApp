import SwiftUI

/// Sheet content for Pure Focus; kept alongside views to honor MVVM separation.
struct PureFocusSheetContent: View {
    @StateObject private var viewModel = PureFocusViewModel()

    private enum SheetIDs {
        static let sheetTopInfo = "sheetTopInfo"
        static let hRow = "hRow"
    }

    private enum DetentValues {
        static let compact = PresentationDetent.fraction(0.1)
        static let medium = PresentationDetent.fraction(0.35)
        static let expanded = PresentationDetent.fraction(0.6)
    }

    private var detents: [PresentationDetent] {
        [DetentValues.compact, DetentValues.medium, DetentValues.expanded]
    }

    private var bottomScreenData: some View {
        HStack(spacing: 0) {
            Text("#4")
                .font(.system(size: 35))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("00:00")
                .fontDesign(Font.Design.monospaced)
                .font(.system(size: 35))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(alignment: .center)
    }

    private func scrollToPreferredView(proxy: ScrollViewProxy, detent: PresentationDetent) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                if detent == DetentValues.expanded {
                    proxy.scrollTo(SheetIDs.hRow, anchor: .top)
                } else {
                    proxy.scrollTo(SheetIDs.sheetTopInfo, anchor: .top)
                }
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    bottomScreenData
                        .id(SheetIDs.sheetTopInfo)
                        .padding(.all, 20)

                    HorizontalContentScrollRow()
                        .id(SheetIDs.hRow)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDragIndicator(viewModel.showDragger ? .visible : .hidden)
        .presentationDetents(detents, selection: Binding(
            get: { viewModel.currentDetent },
            set: { newDetent in
                viewModel.currentDetent = newDetent
                scrollToPreferredView(proxy: proxy, detent: newDetent)
            }
        ))
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    PureFocusSheetContent()
}
