//
//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.
//

import SwiftUI

//need to use white UI elements exclusively.

enum Field: Hashable {
    case leadingText
    case trailingText
}

struct PureFocusView: View {
    
    // MARK: - State Properties
    
    @State private var sheetActive: Bool = true
    @State private var currentDetent: PresentationDetent = .fraction(0.1)
    @FocusState private var focusedField: Field?
    
    // MARK: - ViewModel
    
    // @StateObject creates and owns the model instance
    // Using StateObject ensures the model persists during view redraws
    // This demonstrates proper ownership: the View owns the Model
    @StateObject private var viewModel = PureFocusViewModel() //establish the viewModel

    // IDs used for programmatic scrolling inside the ScrollViewReader.
    // Use constants so it's easy to change or search for the target views.
    private enum SheetIDs {
        static let sheetTopInfo = "sheetTopInfo"
        static let hRow = "hRow"
    }

    // Helper: centralise the scrolling logic so it's easier to read and modify.
    // - proxy: the ScrollViewProxy provided by ScrollViewReader
    // - detent: the new selected PresentationDetent
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

    var body: some View {
        ZStack {
            backgroundGradient //overlay the gradient on the base before other elements
            
            VStack() {
                
                
                topScreenCode
                Spacer()
                    .frame(maxHeight: 150)
                
                Text("Last break: 00:52") //break
                Text("00:00:00")
                    .bold()
                    .font(.system(size: 70))

                
                Spacer()
                
                
                

                

                
                

                

                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)

            
        }
        .overlay(alignment: .center) {
            FocusGoalTimer()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .toolbar(.hidden, for: .tabBar) //hide specifically the tabBar within this view
        .foregroundColor(Color.white)

        .sheet(isPresented: $sheetActive) {
            // Make the sheet content scrollable and control what element stays visible when the detent changes.
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
            // Use viewModel's showDragger property to control visibility
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
    
    
    private var backgroundGradient: some View {
        VStack (spacing: 0) {
            //black to semi back
            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.black.opacity(0.9)],
//                    colors: [Color.black.opacity(1), Color.black.opacity(0.8)],
                
                startPoint: .topLeading,
                endPoint: .bottomLeading
            )
            .statusBarHidden()
            .ignoresSafeArea(edges: .all)
            .frame(maxHeight: 400, alignment: .leading)
            
            
            
            LinearGradient(
                //long black hold
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.7)],
                
                startPoint: .topLeading,
                endPoint: .bottomLeading
            )
            .statusBarHidden()
            .ignoresSafeArea(edges: .all)
            .frame(maxHeight: .infinity, alignment: .leading)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var topScreenCode: some View {
        
        Text("LLLL")
            .font(.system(size: 35))
            .lineLimit(1)
    }
    
    // A simple row with a leading and trailing value.
    // - We attach an `.id` to the whole row when it's used in the sheet so it can be
    //   scrolled-to programmatically (see `SheetIDs.sheetTopInfo`).
    // - The `.focused` modifiers connect each Text view to `@FocusState` so you can
    //   programmatically control focus/keyboard behavior if you replace Text with TextField.
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
}
    
                
#Preview {
    PureFocusView()
}
