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
        if isCurrentUser { return .primary }
        switch status {
        case .studying, .online: return theme.accent
        case .paused: return SocialV4Theme.breakColor
        case .offline: return nil
        }
    }

    private var glowColor: Color {
        if isCurrentUser { return .clear }
        switch status {
        case .studying, .online: return theme.accent.opacity(0.45)
        case .paused: return SocialV4Theme.breakColor.opacity(0.45)
        case .offline: return .clear
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
            if isCurrentUser {
                Circle().fill(theme.accent.opacity(0.30))
            } else {
                Circle().fill(.quaternary)
            }
            Text(initials)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(status == .offline ? .secondary : .primary)
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
    let segment: V4Segment
    let date: Date
    let model: SocialV4PreviewModel

    private var valueSeconds: Int {
        switch segment {
        case .now: return model.todaySeconds(for: friend, at: date)
        case .thisWeek: return model.weekSeconds(for: friend, at: date)
        }
    }

    private var progress: Double {
        let target: Int = segment == .now ? friend.goalSeconds : friend.goalSeconds * 7
        guard target > 0 else { return 0 }
        return min(1.0, Double(valueSeconds) / Double(target))
    }

    private var fillBase: Color {
        friend.status == .paused ? SocialV4Theme.breakColor : theme.accent
    }

    private var subtitle: String {
        switch friend.status {
        case .studying:
            return "\(friend.subjectName ?? "Studying") · live"
        case .paused:
            return "On a break · \(model.breakSeconds(for: friend, at: date) / 60)m"
        case .online:
            return "Online"
        case .offline:
            return "Last seen \(friend.lastSeen ?? "a while ago")"
        }
    }

    private var nameStyle: AnyShapeStyle {
        if friend.isCurrentUser { return AnyShapeStyle(theme.accent) }
        return friend.status == .offline ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)
    }

    private var subtitleStyle: AnyShapeStyle {
        friend.status == .paused ? AnyShapeStyle(SocialV4Theme.breakColor) : AnyShapeStyle(.secondary)
    }

    var body: some View {
        NavigationLink(value: friend.id) {
            HStack(spacing: 12) {
                V4Avatar(
                    initials: friend.initials,
                    status: friend.status,
                    size: 40,
                    isCurrentUser: friend.isCurrentUser
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(.headline)
                        .foregroundStyle(nameStyle)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(subtitleStyle)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(V4Format.duration(valueSeconds))
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(friend.status == .offline ? .secondary : .primary)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var rowBackground: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(.ultraThinMaterial)
            if friend.status != .offline {
                GeometryReader { proxy in
                    goalFill(width: proxy.size.width * CGFloat(progress))
                }
            }
        }
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
    let model: SocialV4PreviewModel

    var body: some View {
        NavigationLink(value: friend.id) {
            VStack(spacing: 4) {
                V4Avatar(
                    initials: friend.initials,
                    status: friend.status,
                    size: 60,
                    isCurrentUser: friend.isCurrentUser
                )
                Text(friend.firstName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                clock
                    .font(.caption2.weight(.medium))
                    .monospacedDigit()
            }
            .frame(width: 60)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var clock: some View {
        if friend.status == .paused {
            Text("break")
                .foregroundStyle(SocialV4Theme.breakColor)
        } else if let start = model.sessionStartDate(for: friend) {
            Text(start, style: .timer)
                .foregroundStyle(.secondary)
        }
    }
}

struct V4SessionAccessory: View {
    @Environment(\.socialV4Theme) private var theme
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    let model: SocialV4PreviewModel
    let onOpen: () -> Void

    private var isInline: Bool { placement == .inline }

    var body: some View {
        if let session = model.session {
            activeContent(session)
        } else {
            Button {
                model.startSession()
            } label: {
                Label("Start session", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    private func activeContent(_ session: SocialV4Mock.Session) -> some View {
        HStack(spacing: 8) {
            Button(action: onOpen) {
                HStack(spacing: 10) {
                    Image(systemName: "book.closed.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(SocialV4Theme.ink, theme.accent)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.subjectName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if !isInline {
                            Text(withText(session))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    Text(timerInterval: model.sessionTimerRange, pauseTime: model.pausedAt, countsDown: false)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(theme.accent)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                model.togglePause()
            } label: {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isPaused ? "Resume" : "Pause")
        }
        .padding(.horizontal)
    }

    private func withText(_ session: SocialV4Mock.Session) -> String {
        let names: [String] = session.withNames
        guard let last = names.last else { return session.subjectCode }
        if names.count == 1 { return "with \(last)" }
        let head: String = names.dropLast().joined(separator: ", ")
        return "with \(head) & \(last)"
    }
}

#Preview {
    ZStack {
        SocialV4Background()
        HStack(spacing: 18) {
            V4Avatar(initials: "MC", status: .studying, size: 60)
            V4Avatar(initials: "JP", status: .paused, size: 60)
            V4Avatar(initials: "BW", status: .studying, size: 60, isCurrentUser: true)
            V4Avatar(initials: "EN", status: .offline, size: 60)
        }
    }
    .environment(\.socialV4Theme, .overcast)
    .environment(\.colorScheme, .dark)
}
