import SwiftUI

struct SocialV4NowView: View {
    @State private var theme: SocialV4Theme = .overcast
    @State private var segment: V4Segment = .now
    @State private var mock = SocialV4Mock.load()
    @State private var loadedAt = Date()

    var body: some View {
        TimelineView(.periodic(from: loadedAt, by: 1)) { context in
            screen(tick: Int(context.date.timeIntervalSince(loadedAt)))
        }
        .environment(\.socialV4Theme, theme)
        .environment(\.colorScheme, .dark)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                themeMenu
            }
        }
    }

    private func screen(tick: Int) -> some View {
        ZStack(alignment: .bottom) {
            SocialV4Background()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    hero(tick: tick)
                    liveStrip(tick: tick)
                    segmentRow
                    list(tick: tick)
                }
                .padding(.bottom, 190)
            }
            .scrollIndicators(.hidden)
            bottomChrome(tick: tick)
        }
    }

    private var themeMenu: some View {
        Menu {
            Picker("Theme", selection: $theme) {
                ForEach(SocialV4Theme.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Image(systemName: "paintpalette")
        }
    }

    private var header: some View {
        HStack {
            Text("Social")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 10) {
                V4GlassCircleButton(accessibilityLabel: "Add friend", action: {}) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                }
                V4GlassCircleButton(accessibilityLabel: "Profile", action: {}) {
                    Text(mock.me.initials)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
        HStack {
            V4SegmentedControl(selection: $segment)
            Spacer()
        }
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

    private func bottomChrome(tick: Int) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, theme.bottom.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 190)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)
            VStack(spacing: 12) {
                V4SessionAccessory(session: mock.session, tick: tick)
                V4MockTabBar()
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    NavigationStack {
        SocialV4NowView()
    }
}
