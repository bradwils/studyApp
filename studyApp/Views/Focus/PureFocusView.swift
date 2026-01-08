//
//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.
//

import SwiftUI

//need to use white UI elements exclusively.


struct PureFocusView: View {
    
    // MARK: - State Properties
    
    @State private var sheetActive: Bool = true

    
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

            
            ContainerRelativeShape()
                            .inset(by: 1) // Inset slightly so the border is visible
                            .stroke(Color.blue, lineWidth: 10)
                            .ignoresSafeArea()

        }
        .toolbar(.hidden, for: .tabBar) //hide specifically the tabBar within this view
        .foregroundColor(Color.white)

        .sheet(isPresented: $sheetActive) {
            
            PureFocusSheetContent()

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
    
}
    
                
#Preview {
    PureFocusView()
}
