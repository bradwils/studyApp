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
            //UITWEAK
            // Apply glass effect to media player card for modern, cohesive appearance
            // The interactive glass effect makes the media controls feel responsive
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08)) // Subtle tint for glass effect
                        .aspectRatio(1.0, contentMode: .fill)
                        .frame(maxWidth: 120, maxHeight: 120)
                        .glassEffect() // Apply glass effect to album art placeholder

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

                    // Play button with interactive glass effect
                    Button(action: {
                        // Play/pause action
                    }) {
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
                    .buttonStyle(.plain) // Use plain style to avoid default button styling
                    .glassEffect(.regular.interactive()) // Add interactive glass to play button
                }
                .padding(.vertical, 12)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.all, 16) // Add padding around the entire card
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05)) // Subtle background for glass effect
            )
            .glassEffect() // Apply glass effect to entire media player card
            //UIEND
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
