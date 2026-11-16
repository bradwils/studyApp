import SwiftUI

// A standalone TabView so the preview gets the real iOS 26 tab bar and bottom accessory,
// which can't be driven from a view pushed inside MainTabView.
struct SocialV4PreviewShell: View {
    @Environment(\.dismiss) private var dismiss
    @State private var theme: SocialV4Theme = .overcast
    @State private var selectedTab: AppTab = .social
    @State private var mock = SocialV4Mock.load()
    @State private var loadedAt = Date()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Focus", systemImage: "book.badge.plus", value: AppTab.focus, role: .search) {
                placeholder("Focus", systemImage: "book.badge.plus")
            }
            Tab("Debug", systemImage: "exclamationmark.triangle.fill", value: AppTab.debug) {
                NavigationStack {
                    previewControls
                }
            }
            Tab("Social", systemImage: "figure.2", value: AppTab.social) {
                NavigationStack {
                    SocialV4NowView(mock: mock, loadedAt: loadedAt)
                }
            }
            Tab("Groups", systemImage: "person.3.fill", value: AppTab.groups) {
                placeholder("Groups", systemImage: "person.3.fill")
            }
            Tab("Sessions", systemImage: "clock.arrow.circlepath", value: AppTab.sessions) {
                placeholder("Sessions", systemImage: "clock.arrow.circlepath")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            TimelineView(.periodic(from: loadedAt, by: 1)) { context in
                V4SessionAccessory(session: mock.session, tick: Int(context.date.timeIntervalSince(loadedAt)))
            }
        }
        .tint(theme.accent)
        .environment(\.socialV4Theme, theme)
        .preferredColorScheme(.dark)
    }

    private var previewControls: some View {
        Form {
            Section("Social V4 preview") {
                Picker("Theme", selection: $theme) {
                    ForEach(SocialV4Theme.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                Button("Close preview", role: .destructive) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Debug")
    }

    private func placeholder(_ title: String, systemImage: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("Not part of this preview"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { SocialV4Background() }
    }
}

struct SocialV4NowView: View {
    @Environment(\.socialV4Theme) private var theme
    @State private var segment: V4Segment = .now

    let mock: SocialV4Mock
    let loadedAt: Date

    var body: some View {
        ScrollView {
            TimelineView(.periodic(from: loadedAt, by: 1)) { context in
                content(tick: Int(context.date.timeIntervalSince(loadedAt)))
            }
        }
        .scrollIndicators(.hidden)
        .background { SocialV4Background() }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add friend", systemImage: "person.badge.plus") {}
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Text(mock.me.initials)
                        .font(.system(size: 14, weight: .semibold))
                }
                .accessibilityLabel("Profile")
            }
        }
    }

    private func content(tick: Int) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            hero(tick: tick)
            liveStrip(tick: tick)
            segmentRow
            list(tick: tick)
        }
        .padding(.top, 4)
        .padding(.bottom, 24)
    }

    private func hero(tick: Int) -> some View {
        let today: Int = mock.me.todaySeconds + tick
        let goal: Int = max(mock.me.goalSeconds, 1)
        let ratio: Double = Double(today) / Double(goal)
        let percent: Int = Int(ratio * 100)
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                Text(V4Format.duration(today))
                    .font(.system(size: 64, weight: .light))
                    .monospacedDigit()
                    .tracking(-2.6)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("\(mock.me.streakDays) days")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SocialV4Theme.breakColor)
                goalBar(ratio: ratio)
                Text("\(percent)% of \(goal / 3600)h")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
    }

    private func goalBar(ratio: Double) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.22))
            Capsule()
                .fill(theme.accent)
                .frame(width: 96 * min(1, ratio))
                .shadow(color: theme.accent.opacity(0.8), radius: 4)
        }
        .frame(width: 96, height: 3)
    }

    private func liveStrip(tick: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Studying now")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(mock.stripFriends.count) of \(mock.friendCount) friends")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(mock.stripFriends) { friend in
                        V4LiveStripItem(friend: friend, tick: tick)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var segmentRow: some View {
        Picker("View", selection: $segment) {
            ForEach(V4Segment.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
        .padding(.horizontal, 20)
    }

    private func list(tick: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(mock.listFriends) { friend in
                V4FriendRow(friend: friend, tick: tick)
            }
        }
        .padding(.vertical, 6)
        .v4Panel()
        .padding(.horizontal, 12)
    }
}

#Preview {
    SocialV4PreviewShell()
}
