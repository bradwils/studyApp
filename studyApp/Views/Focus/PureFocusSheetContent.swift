//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
////OLD SHEET (not usable)
//
//
//import SwiftUI
//
///// Sheet content for Pure Focus; kept alongside views to honor MVVM separation.
//struct PureFocusSheetContent: View {
//    @StateObject private var viewModel = PureFocusViewModel()
//    
//    
//    
//    
//
//    private enum SheetIDs {
//        static let sheetTopInfo = "sheetTopInfo"
//        static let hRow = "hRow"
//    }
//
//    private enum DetentValues { //available detent values
//        static let topContent = PresentationDetent.fraction(0.1)
//        static let fullContentView = PresentationDetent.fraction(0.35)
//        static let expanded = PresentationDetent.fraction(0.6)
//    }
//    
//    //when we call the detents, it's specifically to set them to one of these values (instead of just lifting them)
//    let detents: Set<PresentationDetent> = [DetentValues.topContent, DetentValues.fullContentView, DetentValues.expanded]
//
//
//    private var bottomScreenData: some View {
//        HStack(spacing: 0) {
//            Text("#4")
//                .font(.system(size: 35))
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            Text("00:00")
//                .fontDesign(Font.Design.monospaced)
//                .font(.system(size: 35))
//                .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//        .frame(alignment: .center)
//    }
//
//    private func scrollToPreferredView(proxy: ScrollViewProxy, detent: PresentationDetent) {
//        DispatchQueue.main.async {
//            withAnimation(.easeInOut) {
//                if detent == DetentValues.expanded {
//                    proxy.scrollTo(SheetIDs.hRow, anchor: .top)
//                } else {
//                    proxy.scrollTo(SheetIDs.sheetTopInfo, anchor: .top)
//                }
//            }
//        }
//    }
//
//    var body: some View {
//        ScrollViewReader { proxy in //wrap everything in a scrollviewreader, useful for automatic scrolling of elements
//            ScrollView(.vertical, showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 0) {
//                    // `bottomScreenData` is the small info row at the top of the sheet.
//                    // We mark it with an `id` so we can programmatically scroll to it when needed.
//                    bottomScreenData
//                        .id(SheetIDs.sheetTopInfo)
//                        .padding(.all, 20)
//
//                    // Example content that we might prefer to show when the sheet is expanded.
//                    HorizontalContentScrollRow()
//                        .id(SheetIDs.hRow)
//                }
//                .frame(maxWidth: .infinity, alignment: .top)
//
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            // When the selected detent changes, call our helper to keep the preferred portion of the content visible.
//            .onChange(of: viewModel.currentDetent) { oldDetent, newDetent in
//                scrollToPreferredView(proxy: proxy, detent: newDetent)
//            }
//        }
//        .presentationDragIndicator(viewModel.showDragger ? .visible : .hidden)
//        .presentationDetents(detents, selection: Binding(
//            get: { viewModel.currentDetent },
//            set: { newDetent in
//                viewModel.currentDetent = newDetent
//            }
//        ))
//        .interactiveDismissDisabled(true)
//    }
//}
//
//#Preview {
//    PureFocusSheetContent()
//}
