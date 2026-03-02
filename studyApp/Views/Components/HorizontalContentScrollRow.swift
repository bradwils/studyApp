import SwiftUI

struct HorizontalContentScrollRow: View {
    var body: some View {
        TabView {
            MediaContentTabView()
                .padding(.horizontal)


            LeaderboardSheetView()
                .padding(.horizontal)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 200)
    }
}

struct MediaContentTabView: View {
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    //UITWEAK: Glass effect on media card for native iOS feel
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        // Use glass effect instead of flat color for modern iOS appearance
                        .glassEffect(.regular.interactive())
                        .aspectRatio(1.0, contentMode: .fill)
                        .frame(maxWidth: 120, maxHeight: 120)
                        // Subtle shadow for depth
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                    //UIEND
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now playing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Lo-fi focus mix")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Artist name")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 4)
                        
                        Circle()
                            .trim(from: 0, to: 0.35)
                            .stroke(
                                Color.white.opacity(0.9),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(width: 34, height: 34)
                }
                .padding(.vertical, 12)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal)
    }
}

struct LeaderboardSheetView: View {
    private let topSafeAreaSpacing: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topSafeAreaSpacing)

            List {
                Text("Leaderboard Sheet")
                Text("A")
                Text("A")
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    HorizontalContentScrollRow()
        .background(Color.gray.opacity(0.3))
}
