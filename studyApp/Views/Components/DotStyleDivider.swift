//  DotStyleDivider.swift
//  studyApp
//
//  A dotted line divider component.

import SwiftUI

struct DotStyleDivider: View {
    //call as DotStyleDivider(orientation: .horizontal, length: 123)
    enum Orientation {
        case horizontal
        case vertical
    }

    var orientation: Orientation = .vertical
    var length: CGFloat = 0; //default of 0 if there is nothing defined
    var dotCount: Int { Int(length / 8) }
    var dotSpacing: CGFloat = 6

    private var isHorizontal: Bool { orientation == .horizontal }


    

    var body: some View {

        Rectangle()
            .fill(Color.white.opacity(0.25))
            .frame(
                width: isHorizontal ? length : 1,
                height: isHorizontal ? 1 : length
            )
            .overlay {
                Group {
                    if isHorizontal {
                        HStack(spacing: dotSpacing) {
                            dots
                        }
                    } else {
                        VStack(spacing: dotSpacing) {
                            dots
                        }
                    }
                }
            }
    }

    private var dots: some View { //dots view which overlays the line for the divider
        ForEach(0..<dotCount, id: \.self) { _ in
            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 2, height: 2)
        }
    }
}

#Preview {
    VStack {
        DotStyleDivider(orientation: .horizontal, length: 200)
        DotStyleDivider(orientation: .vertical, length: 100)
    }
}
