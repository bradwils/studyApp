import SwiftUI

struct SocialView: View {

    @State private var viewModel = SocialFeedViewModel()

    var body: some View {
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
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { ScreenBackground() }
        .navigationTitle("Social")
        .toolbarTitleDisplayMode(.large)
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
