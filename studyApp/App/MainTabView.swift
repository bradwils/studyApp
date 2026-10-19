import SwiftUI

enum AppTab: Hashable {
    case focus, debug, social, groups, sessions
}

struct MainTabView: View {
    @Environment(AppSession.self) private var appSession

    var body: some View {
		//Bindable allows for us to create a reference that we can use below to talk to selectedTab within the appSession.
        @Bindable var session = appSession
        TabView(selection: $session.selectedTab) {

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
		.environment(AppSession())
}
