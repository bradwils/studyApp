import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Derived lists
    // Split friends into active (studying) and resting for separate sections.
    private var studyingFriends: [SocialFeedItem] { viewModel.items.filter { !$0.isLocked } }
    private var restingFriends:  [SocialFeedItem] { viewModel.items.filter {  $0.isLocked } }

    // MARK: - Background gradient
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
                    // Header: "Your Study Day" with stat cards + friends chip
                    DashboardHeader(
                        currentSessionTime: viewModel.currentSessionTime,
                        currentSubject: viewModel.currentSubject,
                        streakCount: viewModel.streakCount,
                        totalDailyTime: viewModel.totalDailyTime
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // MARK: "Studying Now" section
                    if !studyingFriends.isEmpty {
                        feedSectionHeader(title: "Studying Now", count: studyingFriends.count, color: .green)
                        friendList(studyingFriends)
                    }

                    // MARK: "Taking a Break" section
                    if !restingFriends.isEmpty {
                        feedSectionHeader(title: "Taking a Break", count: restingFriends.count, color: .gray.opacity(0.6))
                        friendList(restingFriends)
                    }
                    //UIEND

                    Spacer().frame(height: 24)
                }
            }
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(colorScheme == .dark ? Color.black : Color.white)
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
    }

    // MARK: - Section helpers

    /// A section header row with a title and a coloured count pill.
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

    /// A lazy list of friend cards with navigation links.
    @ViewBuilder
    private func friendList(_ items: [SocialFeedItem]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
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
    }
}

#Preview {
    NavigationStack {
        SocialView()
    }
}
