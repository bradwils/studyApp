//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.
//

import SwiftUI

//need to use white UI elements exclusively.
struct PureFocusView: View {
    
    // MARK: - State Properties
    
    @StateObject private var viewModel = PureFocusViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGradient
            
            VStack() {
                topScreenCode
                Spacer()
                    .frame(maxHeight: 150)
                
                Text("Last break: 00:52")
                Text("00:00:00")
                    .bold()
                    .font(.system(size: 70))
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            
            ContainerRelativeShape()
                .inset(by: 1)
                .stroke(Color.blue, lineWidth: 10)
                .ignoresSafeArea()

            CustomBottomSheet()
        }
        .toolbar(.hidden, for: .tabBar)
        .foregroundColor(Color.white)
        .navigationBarBackButtonHidden(false)
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
    
