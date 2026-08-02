import SwiftUI

struct HorizontalContentScrollRow: View {
    // A paged TabView never reports an intrinsic height — it always fills whatever it is
    // offered — so the row needs a definite one. Scaled so it grows with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 200

    var body: some View {
        TabView {
            MediaContentTabView()
                .padding(.horizontal)


            LeaderboardSheetView()
                .padding(.horizontal)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: rowHeight)
    }
}

struct MediaContentTabView: View {
    @ScaledMetric(relativeTo: .subheadline) private var artworkSize: CGFloat = 120
    @ScaledMetric(relativeTo: .caption) private var playButtonSize: CGFloat = 34

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .aspectRatio(1.0, contentMode: .fill)
                .frame(maxWidth: artworkSize, maxHeight: artworkSize)

            VStack(alignment: .leading) {
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
                    .fill(Color.primary.opacity(0.12))

                Circle()
                    .trim(from: 0, to: 0.35)
                    .stroke(
                        Color.white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Image(systemName: "play.fill")
                    .font(.caption.weight(.bold))
            }
            .frame(width: playButtonSize, height: playButtonSize)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

struct LeaderboardSheetView: View {
    var body: some View {
        List {
            Text("Leaderboard Sheet")
            Text("A")
            Text("A")
        }
        .listStyle(.plain)
    }
}

#Preview {
    HorizontalContentScrollRow()
        .background(Color.gray.opacity(0.3))
}
