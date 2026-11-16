import SwiftUI

struct V4Avatar: View {
    @Environment(\.socialV4Theme) private var theme

    let initials: String
    let status: ActiveStatus
    let size: CGFloat
    let isCurrentUser: Bool

    init(initials: String, status: ActiveStatus, size: CGFloat, isCurrentUser: Bool = false) {
        self.initials = initials
        self.status = status
        self.size = size
        self.isCurrentUser = isCurrentUser
    }

    private var ringColor: Color? {
        if isCurrentUser { return Color.white }
        switch status {
        case .studying, .online: return theme.accent
        case .paused: return SocialV4Theme.breakColor
        case .offline: return nil
        }
    }

    private var glowColor: Color {
        if isCurrentUser { return Color.clear }
        switch status {
        case .studying, .online: return theme.accent.opacity(0.45)
        case .paused: return SocialV4Theme.breakColor.opacity(0.45)
        case .offline: return Color.clear
        }
    }

    private var statusText: String {
        switch status {
        case .studying: return "studying"
        case .online: return "online"
        case .paused: return "on a break"
        case .offline: return "offline"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isCurrentUser ? theme.accent.opacity(0.30) : Color.white.opacity(0.16))
            Text(initials)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(status == .offline ? Color.white.opacity(0.72) : Color.white)
        }
        .frame(width: size, height: size)
        .overlay {
            if let ring = ringColor {
                Circle().strokeBorder(ring, lineWidth: 2)
            }
        }
        .shadow(color: glowColor, radius: size / 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(initials), \(statusText)")
    }
}

struct V4FriendRow: View {
    @Environment(\.socialV4Theme) private var theme

    let friend: SocialV4Mock.Friend
    let tick: Int

    init(friend: SocialV4Mock.Friend, tick: Int) {
        self.friend = friend
        self.tick = tick
    }

    private var todayLive: Int {
        friend.todaySeconds + (friend.isLive ? tick : 0)
    }

    private var progress: Double {
        guard friend.goalSeconds > 0 else { return 0 }
        return min(1.0, Double(todayLive) / Double(friend.goalSeconds))
    }

    private var fillBase: Color {
        friend.status == .paused ? SocialV4Theme.breakColor : theme.accent
    }

    private var subtitle: String {
        switch friend.status {
        case .studying, .online:
            return "\(friend.subjectName ?? "Studying") · live"
        case .paused:
            let minutes: Int = ((friend.breakSeconds ?? 0) + tick) / 60
            return "On a break · \(minutes)m"
        case .offline:
            return "Last seen \(friend.lastSeen ?? "a while ago")"
        }
    }

    private var subtitleColor: Color {
        friend.status == .paused ? SocialV4Theme.breakColor : Color.white.opacity(0.72)
    }

    private var nameColor: Color {
        if friend.isCurrentUser { return theme.accent }
        return friend.status == .offline ? Color.white.opacity(0.75) : Color.white
    }

    var body: some View {
        HStack(spacing: 12) {
            V4Avatar(
                initials: friend.initials,
                status: friend.status,
                size: 40,
                isCurrentUser: friend.isCurrentUser
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(V4Format.duration(todayLive))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(friend.status == .offline ? Color.white.opacity(0.70) : Color.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
        .background(alignment: .leading) {
            if friend.status != .offline {
                GeometryReader { proxy in
                    goalFill(width: proxy.size.width * CGFloat(progress))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func goalFill(width: CGFloat) -> some View {
        let startOpacity: Double = friend.isCurrentUser ? 0.10 : 0.03
        let endOpacity: Double = friend.isCurrentUser ? 0.30 : 0.15
        let edgeOpacity: Double = friend.isCurrentUser ? 0.80 : 0.45
        return ZStack(alignment: .trailing) {
            LinearGradient(
                colors: [fillBase.opacity(startOpacity), fillBase.opacity(endOpacity)],
                startPoint: .leading,
                endPoint: .trailing
            )
            Rectangle()
                .fill(fillBase.opacity(edgeOpacity))
                .frame(width: 1)
        }
        .frame(width: width)
    }
}

struct V4LiveStripItem: View {
    let friend: SocialV4Mock.Friend
    let tick: Int

    init(friend: SocialV4Mock.Friend, tick: Int) {
        self.friend = friend
        self.tick = tick
    }

    var body: some View {
        VStack(spacing: 4) {
            V4Avatar(
                initials: friend.initials,
                status: friend.status,
                size: 60,
                isCurrentUser: friend.isCurrentUser
            )
            Text(friend.firstName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            if friend.status == .paused {
                Text("break")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(SocialV4Theme.breakColor)
            } else {
                Text(V4Format.clock((friend.sessionSeconds ?? 0) + tick))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.78))
            }
        }
        .frame(width: 60)
        .accessibilityElement(children: .combine)
    }
}

enum V4Segment: String, CaseIterable {
    case now = "Now"
    case thisWeek = "This week"
}

struct V4SegmentedControl: View {
    @Binding var selection: V4Segment

    init(selection: Binding<V4Segment>) {
        self._selection = selection
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(V4Segment.allCases, id: \.self) { segment in
                segmentButton(segment)
            }
        }
        .padding(3)
        .v4GlassControl(in: Capsule())
    }

    private func segmentButton(_ segment: V4Segment) -> some View {
        let isSelected: Bool = selection == segment
        return Button {
            withAnimation(.snappy) {
                selection = segment
            }
        } label: {
            Text(segment.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? SocialV4Theme.ink : Color.white.opacity(0.82))
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background {
                    if isSelected {
                        Capsule().fill(Color.white)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct V4GlassCircleButton<Label: View>: View {
    let accessibilityLabel: String
    let action: () -> Void
    let label: Label

    init(
        accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .v4GlassControl(in: Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct V4SessionAccessory: View {
    @Environment(\.socialV4Theme) private var theme

    let session: SocialV4Mock.Session
    let tick: Int

    init(session: SocialV4Mock.Session, tick: Int) {
        self.session = session
        self.tick = tick
    }

    private var withText: String {
        let names: [String] = session.withNames
        guard let last = names.last else { return session.subjectCode }
        if names.count == 1 { return "with \(last)" }
        let head: String = names.dropLast().joined(separator: ", ")
        return "with \(head) & \(last)"
    }

    var body: some View {
        Button {
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SocialV4Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.accent))
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.subjectName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text(withText)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(V4Format.clock(session.elapsedSeconds + tick))
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.accent)
                Image(systemName: "pause.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 8)
            .frame(height: 54)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .v4TabGlass(in: Capsule())
        .accessibilityLabel("Current session, \(session.subjectName), \(withText)")
    }
}

private struct V4TabItem: Identifiable {
    let title: String
    let symbol: String
    let isSelected: Bool
    var id: String { title }
}

struct V4MockTabBar: View {
    @Environment(\.socialV4Theme) private var theme

    private let tabs: [V4TabItem] = [
        V4TabItem(title: "Debug", symbol: "exclamationmark.triangle.fill", isSelected: false),
        V4TabItem(title: "Social", symbol: "figure.2", isSelected: true),
        V4TabItem(title: "Groups", symbol: "person.3.fill", isSelected: false),
        V4TabItem(title: "Sessions", symbol: "clock.arrow.circlepath", isSelected: false)
    ]

    init() {}

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    tabCell(tab)
                }
            }
            .padding(4)
            .frame(height: 62)
            .v4TabGlass(in: Capsule())

            Image(systemName: "book.badge.plus")
                .font(.system(size: 22))
                .foregroundStyle(Color.white)
                .frame(width: 62, height: 62)
                .v4TabGlass(in: Circle())
                .accessibilityLabel("Focus")
        }
    }

    private func tabCell(_ tab: V4TabItem) -> some View {
        VStack(spacing: 2) {
            Image(systemName: tab.symbol)
                .font(.system(size: 22))
                .frame(height: 26)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(tab.isSelected ? theme.accent : Color.white.opacity(0.85))
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            if tab.isSelected {
                Capsule().fill(Color.white.opacity(0.14))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(tab.isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        SocialV4Background()
        VStack(spacing: 24) {
            HStack(spacing: 18) {
                V4Avatar(initials: "MC", status: .studying, size: 60)
                V4Avatar(initials: "JP", status: .paused, size: 60)
                V4Avatar(initials: "BW", status: .studying, size: 60, isCurrentUser: true)
                V4Avatar(initials: "EN", status: .offline, size: 60)
            }
            V4SegmentedControl(selection: .constant(.now))
            V4MockTabBar()
                .padding(.horizontal, 16)
        }
    }
    .environment(\.socialV4Theme, .overcast)
    .environment(\.colorScheme, .dark)
}
