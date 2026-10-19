import SwiftUI

enum AppTab: Hashable {
    case focus, debug, social, groups, sessions
}

struct MainTabView: View {
    @State private var selection: AppTab = .focus

    var body: some View {
        TabView(selection: $selection) {

            Tab("Focus", systemImage: "book.badge.plus", value: AppTab.focus, role: .search) {
                NavigationStack {
                    FocusSessionScreen()
                }
            }
            
            Tab("Debug", systemImage: "exclamationmark.triangle.fill", value: AppTab.debug) {
                NavigationStack {
					SettingsView()
                }
            }
            
            Tab("Social", systemImage: "figure.2", value: AppTab.social) {
                NavigationStack {
                    SocialView()
                }
            }
            
            Tab("Groups", systemImage: "person.3.fill", value: AppTab.groups) {
                NavigationStack {
                    GroupsView()
                }
            }
            
            Tab("Sessions", systemImage: "clock.arrow.circlepath", value: AppTab.sessions) {
                NavigationStack {
                    SessionsView()
                }
            }
        }
    }
}

#Preview {
	MainTabView()
}
