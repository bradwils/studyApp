import SwiftUI

struct V4SessionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let model: SocialV4PreviewModel

    var body: some View {
        NavigationStack {
            Group {
                if let session = model.session {
                    sessionForm(session)
                } else {
                    ContentUnavailableView {
                        Label("No active session", systemImage: "book.closed")
                    } description: {
                        Text("Start a session to track your study time.")
                    } actions: {
                        Button("Start session") { model.startSession() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sessionForm(_ session: SocialV4Mock.Session) -> some View {
        Form {
            Section {
                LabeledContent("Subject", value: session.subjectName)
                LabeledContent("Code", value: session.subjectCode)
                LabeledContent("With", value: session.withNames.formatted(.list(type: .and)))
                LabeledContent("Elapsed") {
                    Text(timerInterval: model.sessionTimerRange, pauseTime: model.pausedAt, countsDown: false)
                        .monospacedDigit()
                }
            }
            Section {
                Button(
                    model.isPaused ? "Resume" : "Pause",
                    systemImage: model.isPaused ? "play.fill" : "pause.fill"
                ) {
                    model.togglePause()
                }
                Button("End session", role: .destructive) {
                    model.endSession()
                    dismiss()
                }
            }
        }
    }
}

struct V4AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    let model: SocialV4PreviewModel

    private var results: [SocialV4Mock.Friend] {
        guard !query.isEmpty else { return model.suggestions }
        return model.suggestions.filter { $0.name.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(results) { suggestion in
                HStack(spacing: 12) {
                    V4Avatar(initials: suggestion.initials, status: suggestion.status, size: 40)
                    Text(suggestion.name)
                        .font(.headline)
                    Spacer(minLength: 8)
                    Button("Add") { model.add(suggestion) }
                        .buttonStyle(.bordered)
                }
            }
            .overlay {
                if model.suggestions.isEmpty {
                    ContentUnavailableView(
                        "No suggestions",
                        systemImage: "person.2",
                        description: Text("You have added everyone we could find.")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query)
            .navigationTitle("Add friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct V4FriendDetailView: View {
    let model: SocialV4PreviewModel
    let friendID: String

    var body: some View {
        Group {
            if let friend = model.friend(id: friendID) {
                TimelineView(.periodic(from: model.loadedAt, by: 1)) { context in
                    detailForm(friend, at: context.date)
                }
                .navigationTitle(friend.name)
            } else {
                ContentUnavailableView("Friend not found", systemImage: "person.slash")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailForm(_ friend: SocialV4Mock.Friend, at date: Date) -> some View {
        let today: Int = model.todaySeconds(for: friend, at: date)
        let goal: Int = friend.goalSeconds
        let progress: Double = goal > 0 ? min(1.0, Double(today) / Double(goal)) : 0
        return Form {
            Section {
                HStack(spacing: 12) {
                    V4Avatar(
                        initials: friend.initials,
                        status: friend.status,
                        size: 56,
                        isCurrentUser: friend.isCurrentUser
                    )
                    Text(friend.name)
                        .font(.title3.weight(.semibold))
                }
            }
            Section {
                LabeledContent("Status", value: statusText(friend))
                if let subject = friend.subjectName {
                    LabeledContent("Subject", value: subject)
                }
                LabeledContent("Today", value: V4Format.duration(today))
                LabeledContent("This week", value: V4Format.duration(model.weekSeconds(for: friend, at: date)))
                LabeledContent("Daily goal") {
                    ProgressView(value: progress)
                        .frame(width: 120)
                }
            }
        }
    }

    private func statusText(_ friend: SocialV4Mock.Friend) -> String {
        switch friend.status {
        case .studying: return "Studying"
        case .paused: return "On a break"
        case .online: return "Online"
        case .offline: return "Last seen \(friend.lastSeen ?? "a while ago")"
        }
    }
}
