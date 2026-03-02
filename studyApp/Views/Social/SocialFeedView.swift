import SwiftUI

struct SocialView: View {
    /// Dedicated ViewModel keeps the feed data and summary in one place.
    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Background gradient
    // Layered radial + linear gradients give the header area a colourful tint
    // that fades into the plain background below the fold.
    private var backgroundGradient: some View {
        ZStack {
            RadialGradient(
                colors: colorScheme == .dark
                ? [Color.yellow.opacity(0.8), Color.black.opacity(0.8)]
                : [Color.yellow.opacity(0.8), Color.white.opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            .frame(height: 300)

            LinearGradient(
                colors: [Color.white.opacity(0.5), Color.pink.opacity(0.5), Color.blue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)

            LinearGradient(
                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            .frame(height: 300)

            LinearGradient(
                colors: colorScheme == .dark
                ? [Color.black.opacity(0), Color.black.opacity(1)]
                : [Color.white.opacity(0), Color.white.opacity(1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    //UITWEAK
                    // Session summary card sits just below the nav title.
                    DashboardHeader(
                        currentSessionTime: viewModel.currentSessionTime,
                        currentSubject: viewModel.currentSubject,
                        streakCount: viewModel.streakCount,
                        totalDailyTime: viewModel.totalDailyTime
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Section label above the friends list
                    Text("Friends")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 10)

                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.items) { item in
                            // .hoverEffect(.highlight) adds the system pointer hover highlight
                            // on iPadOS/macOS (Catalyst), keeping the feel native across platforms.
                            NavigationLink {
                                StudyMemberDetailView(memberName: item.name)
                            } label: {
                                StudyItemCard(item: item)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(.highlight)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollEdgeEffectStyle(.automatic, for: .top)
                    .padding(.bottom, 24)
                    //UIEND
                }
            }
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(colorScheme == .dark ? Color.black : Color.white)
        //UITWEAK
        // Avatar/profile menu moved into the navigation toolbar — this is the standard
        // iOS pattern (see Mail, Contacts, Health). It keeps the scroll area clean and
        // gives the button a consistent, expected location for users.
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink("Settings") { SettingsView() }
                    NavigationLink("Profile") { StudyMemberDetailView(memberName: "Preview User 0") }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
            }
        }
        //UIEND
    }

}

#Preview {
    NavigationStack {
        SocialView()
    }
}
