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
        .toolbar(.hidden, for: .tabBar) //hide specifically the tabBar within this view
        .foregroundColor(Color.white)

        .sheet(isPresented: $sheetActive) {
            VStack(alignment: .leading, spacing: 0) {
                bottomScreenData
                    .padding(.horizontal, 20)
                
                HorizontalContentScrollRow()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Use viewModel's showDragger property to control visibility
            .presentationDragIndicator(viewModel.showDragger ? .visible : .hidden)
            // Custom binding: wraps $currentDetent to call viewModel.updateDraggerVisibility whenever it changes
            // get: returns the current value of currentDetent
            // set: updates currentDetent AND notifies the viewModel of the change
            .presentationDetents([.fraction(0.1), .fraction(0.2), .fraction(0.6)], selection: Binding(
                get: { currentDetent },
                set: { newDetent in
                    currentDetent = newDetent
                    viewModel.updateDraggerVisibility(for: newDetent)
                }
            ))
            .interactiveDismissDisabled(true)
            .presentationBackground(.ultraThinMaterial)
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
    
    private var bottomScreenData: some View {

        HStack(spacing: 0) {
                 Text("#4")
                     .font(.system(size: 35))
                .frame(maxWidth: .infinity, alignment: .leading)
                .focused($focusedField, equals: .leadingText)



             Text("00:00")
                 .fontDesign(Font.Design.monospaced)
                 .font(.system(size: 35))
                 .frame(maxWidth: .infinity, alignment: .trailing)
                 .focused($focusedField, equals: .trailingText)
        }
        .frame(alignment: .center) //force middle element to align center
    }
}
    
                
#Preview {
    PureFocusView()
}

