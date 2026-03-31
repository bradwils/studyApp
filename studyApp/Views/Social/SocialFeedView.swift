import SwiftUI

// MARK: - SocialView

struct SocialView: View {

    // MARK: State

    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.colorScheme) var colorScheme

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: Background
            backgroundGradient
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)

            // MARK: Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Dashboard header (stats + streak)
                    DashboardHeader(
                        currentSessionTime: viewModel.currentSessionTime,
                        currentSubject: viewModel.currentSubject,
                        streakCount: viewModel.streakCount,
                        totalDailyTime: viewModel.totalDailyTime,
                        onlineFriends: viewModel.onlineFriendsCount
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    ForEach(viewModel.feedSections) { section in
                        feedSectionHeader(title: section.title, count: section.count, color: section.color)
                        friendList(section.items, online: section.isOnline)
                    }

                    Spacer().frame(height: 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .toolbar {
            // MARK: Profile / settings menu (toolbar)
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
    }

    // MARK: - Background gradient

    private var backgroundGradient: some View {
        ZStack {
            RadialGradient(
                colors: colorScheme == .dark
                    ? viewModel.backgroundRadialColors
                    : viewModel.backgroundLightRadialColors,
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

    // MARK: - Section helpers

    
    /// A section header label with a coloured count pill.
    @ViewBuilder
    private func feedSectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 10)
    }

    /// A list of friend cards with navigation links.
    /// Uses OnlineUserCard for studying friends, OfflineUserCard for resting friends.
    @ViewBuilder
    private func friendList(_ items: [SocialFeedItem], online: Bool) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
                NavigationLink {
                    StudyMemberDetailView(memberName: item.name)
                } label: {
                    if online {
                        OnlineUserCard(item: item)
                            .padding(.horizontal, 16)
                    } else {
                        OfflineUserCard(item: item)
                            .padding(.horizontal, 16)
                    }
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SocialView()
    }
}
