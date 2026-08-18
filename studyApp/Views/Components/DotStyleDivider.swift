//  DotStyleDivider.swift
//  studyApp
//
//  A dotted line divider component.

import SwiftUI

struct DotStyleDivider: View {
    //call as DotStyleDivider(orientation: .horizontal)
    enum Orientation {
        case horizontal
        case vertical
    }

    var orientation: Orientation

    @ScaledMetric(relativeTo: .caption) private var lineThickness: CGFloat = 1
    @ScaledMetric(relativeTo: .caption) private var dotSize: CGFloat = 2
    @ScaledMetric(relativeTo: .caption) private var dotSpacing: CGFloat = 6

    private var isHorizontal: Bool { orientation == .horizontal }

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.25))
            .frame(
                width: isHorizontal ? nil : lineThickness,
                height: isHorizontal ? lineThickness : nil
            )
            .overlay { dots }
    }

    // Near-zero dash segments under a round cap draw as dots, so the run repeats
    // for however long the divider ends up being instead of a counted length.
    private var dots: some View {
        DividerLine(isHorizontal: isHorizontal)
            .stroke(
                Color.white.opacity(0.25),
                style: StrokeStyle(
                    lineWidth: dotSize,
                    lineCap: .round,
                    dash: [0.01, dotSize + dotSpacing]
                )
            )
    }
}

private struct DividerLine: Shape {
    var isHorizontal: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isHorizontal {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        return path
    }
}

#Preview {
	
    HStack {
		Spacer()
        DotStyleDivider(orientation: .vertical)

        VStack {
            
            DotStyleDivider(orientation: .horizontal)
            
        }
    }
	.frame(alignment: .center)
    .padding()
    .background(Color.black)
}
