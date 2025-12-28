//
//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.
//

import SwiftUI

//need to use white UI elements exclusively.

struct PureFocusView: View {
    
    
    
    var body: some View {
        ZStack {
            backgroundGradient //overlay the gradient on the base before other elements
            
            VStack() {
                
                
                topScreenCode
                
                Spacer()
                
                bottomScreenData
                

                

                
                

                

                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)


        }
        
        .foregroundColor(Color.white)

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

