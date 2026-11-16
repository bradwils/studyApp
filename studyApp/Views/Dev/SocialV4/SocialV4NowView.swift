import SwiftUI

// A standalone TabView so the preview gets the real iOS 26 tab bar and bottom accessory,
// which can't be driven from a view pushed inside MainTabView.
struct SocialV4PreviewShell: View {
    @Environment(\.dismiss) private var dismiss
    @State private var theme: SocialV4Theme = .overcast
    @State private var selectedTab: AppTab = .social
    @State private var model = SocialV4PreviewModel()
    @State private var isShowingSession = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Focus", systemImage: "book.badge.plus", value: AppTab.focus, role: .search) {
                focusPlaceholder
            }
            Tab("Debug", systemImage: "exclamationmark.triangle.fill", value: AppTab.debug) {
                NavigationStack {
                    previewControls
                }
            }
            Tab("Social", systemImage: "figure.2", value: AppTab.social) {
                NavigationStack {
                    SocialV4NowView(model: model, theme: $theme, onClose: { dismiss() })
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
        .modifier(
            V4BottomAccessoryModifier(isEnabled: model.session != nil) {
                V4SessionAccessory(model: model) { isShowingSession = true }
            }
        )
        .sheet(isPresented: $isShowingSession) {
            V4SessionSheet(model: model)
                .environment(\.socialV4Theme, theme)
                .tint(theme.accent)
                .preferredColorScheme(.dark)
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
            Section("Session") {
                if model.session == nil {
                    Button("Start session") { model.startSession() }
                } else {
                    Button(model.isPaused ? "Resume session" : "Pause session") { model.togglePause() }
                    Button("End session", role: .destructive) { model.endSession() }
                }
            }
        }
        .navigationTitle("Debug")
    }

    private var focusPlaceholder: some View {
        ContentUnavailableView {
            Label("Focus", systemImage: "book.badge.plus")
        } description: {
            Text("Not part of this preview")
        } actions: {
            if model.session == nil {
                Button("Start mock session") { model.startSession() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SocialV4Background() }
    }

    private func placeholder(_ title: String, systemImage: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("Not part of this preview"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { SocialV4Background() }
    }
}

// tabViewBottomAccessory(isEnabled:) needs iOS 26.1; the deployment target is 26.0.
private struct V4BottomAccessoryModifier<Accessory: View>: ViewModifier {
    let isEnabled: Bool
    let accessory: Accessory

    init(isEnabled: Bool, @ViewBuilder accessory: () -> Accessory) {
        self.isEnabled = isEnabled
        self.accessory = accessory()
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isEnabled) { accessory }
        } else {
            content.tabViewBottomAccessory { accessory }
        }
    }
}

struct SocialV4NowView: View {
    @State private var segment: V4Segment = .now
    @State private var isShowingAddFriend = false

    let model: SocialV4PreviewModel
    @Binding var theme: SocialV4Theme
    let onClose: () -> Void

    var body: some View {
        TimelineView(.periodic(from: model.loadedAt, by: 1)) { context in
            List {
                heroSection(date: context.date)
                liveSection
                friendsSection(date: context.date)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background { SocialV4Background() }
            .scrollIndicators(.hidden)
            .animation(.default, value: segment)
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: String.self) { friendID in
            V4FriendDetailView(model: model, friendID: friendID)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add friend", systemImage: "person.badge.plus") {
                    isShowingAddFriend = true
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                profileMenu
            }
        }
        .sheet(isPresented: $isShowingAddFriend) {
            V4AddFriendSheet(model: model)
                .environment(\.socialV4Theme, theme)
                .tint(theme.accent)
                .preferredColorScheme(.dark)
        }
    }

    private var profileMenu: some View {
        Menu {
            Picker("Theme", selection: $theme) {
                ForEach(SocialV4Theme.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            Button("Close preview", role: .destructive, action: onClose)
        } label: {
            Text(model.me.initials)
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityLabel("Profile")
    }

    private func heroSection(date: Date) -> some View {
        let today: Int = model.friends.first(where: \.isCurrentUser).map { model.todaySeconds(for: $0, at: date) } ?? 0
        let goal: Int = max(model.me.goalSeconds, 1)
        let ratio: Double = Double(today) / Double(goal)
        return Section {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(V4Format.duration(today))
                        .font(.system(size: 64, weight: .light))
                        .monospacedDigit()
                        .tracking(-2.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 6) {
                    Label("\(model.me.streakDays) days", systemImage: "flame.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SocialV4Theme.breakColor)
                    ProgressView(value: min(1, ratio))
                        .tint(theme.accent)
                        .frame(width: 96)
                    Text("\(Int(ratio * 100))% of \(goal / 3600)h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 10)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var liveSection: some View {
        Section {
            Group {
                if model.stripFriends.isEmpty {
                    Text("No friends are studying right now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            ForEach(model.stripFriends) { friend in
                                V4LiveStripItem(friend: friend, model: model)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } header: {
            HStack {
                Text("Studying now")
                    .font(.headline)
                Spacer()
                Text("\(model.stripFriends.count) of \(model.friendCount) friends")
                    .font(.footnote)
            }
            .textCase(nil)
        }
    }

    private func friendsSection(date: Date) -> some View {
        Section {
            ForEach(model.listFriends(for: segment)) { friend in
                V4FriendRow(friend: friend, segment: segment, date: date, model: model)
            }
        } header: {
            Picker("View", selection: $segment) {
                ForEach(V4Segment.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .textCase(nil)
        }
    }
}

#Preview {
    SocialV4PreviewShell()
}
