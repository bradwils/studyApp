import SwiftUI

struct SocialView: View {

    @State private var viewModel = SocialFeedViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DashboardHeader(
                        currentSessionTime: viewModel.currentSessionTime,
                        currentSubject: viewModel.currentSubject,
                        streakCount: viewModel.streakCount,
                        totalDailyTime: viewModel.totalDailyTime,
                        onlineFriends: viewModel.activeFriends.count
                    )
                    .padding(.horizontal, DS.Space.l)
                    .padding(.top, DS.Space.m)

                    if !viewModel.activeFriends.isEmpty {
                        sectionHeader("Active now", count: viewModel.activeFriends.count, tint: DS.Color.active)
                        friendList(viewModel.activeFriends)
                    }

                    if !viewModel.offlineFriends.isEmpty {
                        sectionHeader("Offline", count: viewModel.offlineFriends.count, tint: DS.Color.offline)
                        friendList(viewModel.offlineFriends)
                    }
                }
                .padding(.bottom, DS.Space.xxl)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink("Settings") { SettingsView() }
                    NavigationLink("My Profile") { StudyMemberDetailView(memberName: "Preview User 0") }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Profile and settings")
            }
        }
    }

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

    private func sectionHeader(_ title: String, count: Int, tint: Color) -> some View {
        SectionHeader(title: title, count: count, tint: tint)
            .padding(.horizontal, DS.Space.l)
            .padding(.top, DS.Space.xxl)
            .padding(.bottom, DS.Space.s)
    }

    private func friendList(_ items: [SocialFeedItem]) -> some View {
        LazyVStack(spacing: DS.Space.s) {
            ForEach(items) { item in
                NavigationLink {
                    StudyMemberDetailView(memberName: item.name)
                } label: {
                    FriendCard(item: item)
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
        }
        .padding(.horizontal, DS.Space.l)
    }
}

#Preview {
    NavigationStack {
        SocialView()
    }
}
