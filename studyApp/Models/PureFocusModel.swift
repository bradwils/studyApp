//
//  PureFocusModel.swift
//  studyApp
//
//  DEPRECATED: This file has been refactored for MVVM.
//  - ViewModel moved to: ViewModels/PureFocusViewModel.swift
//
//  This file provides backward compatibility and can be removed after verifying build success.

import SwiftUI
import Combine

// MARK: - Backward Compatibility Alias

typealias PureFocusModel = PureFocusViewModel


public struct PureFocusSheetContent: View {
    
    @StateObject private var viewModel = PureFocusViewModel()
    
    @State private var currentDetent: PresentationDetent = .fraction(0.1)

    
    
    private enum SheetIDs {
        static let sheetTopInfo = "sheetTopInfo"
        static let hRow = "hRow"
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
        .frame(alignment: .center) //force middle element to align center
    }
    
    
    private func scrollToPreferredView(proxy: ScrollViewProxy, detent: PresentationDetent) {
        // We dispatch to the main runloop to ensure the ScrollView's layout is updated
        // before attempting to scroll. This avoids trying to scroll to an item that
        // hasn't been laid out in the view hierarchy yet.
        DispatchQueue.main.async {
            withAnimation(.easeInOut) { //can do 'if detent = fraction(0.6) {do this} if you want specifics
                proxy.scrollTo(SheetIDs.sheetTopInfo, anchor: .top)
            }
        }
    }
    
    public var body: some View {
//        Text("Pure Focus Sheet Content")
        
            ScrollViewReader { proxy in //wrap everything in a scrollviewreader, useful for automatic scrolling of elements
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // `bottomScreenData` is the small info row at the top of the sheet.
                        // We mark it with an `id` so we can programmatically scroll to it when needed.
                        bottomScreenData
                            .id(SheetIDs.sheetTopInfo)
                            .padding(.all, 20)

                        // Example content that we might prefer to show when the sheet is expanded.
                        HorizontalContentScrollRow()
                            .id(SheetIDs.hRow)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // When the selected detent changes, call our helper to keep the preferred portion of the content visible.
                .onChange(of: currentDetent) { oldDetent, newDetent in
                    scrollToPreferredView(proxy: proxy, detent: newDetent)
                }
            }

        //MARK: presentation modifiers
        
                .presentationDragIndicator(viewModel.showDragger ? .visible : .hidden)
                // Custom binding: wraps $currentDetent to call viewModel.updateDraggerVisibility whenever it changes
                // get: returns the current value of currentDetentw
                // set: updates currentDetent AND notifies the viewModel of the change
                .presentationDetents([ .fraction(0.1), .fraction(0.35), .fraction(0.6)], selection: Binding(
                    get: { currentDetent },
                    set: { newDetent in
                        currentDetent = newDetent
                        viewModel.updateDraggerVisibility(for: newDetent)
                    }
                ))
                .interactiveDismissDisabled(true)
        
        
        
        
        
        
        
    }
}






//MARK: - PureFocus Sheet

