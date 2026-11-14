import SwiftUI
import OSLog
import SwiftData

enum AppTab: Hashable {
    case focus, debug, social, groups, sessions
}

struct MainTabView: View {
//	let tabViewLogger = Logger(subsystem: "com.studyApp", category: "tabView")
    @Environment(AppSession.self) private var appSession

    let tracking: StudyTrackingViewModel

    var body: some View {
		//Bindable allows for us to create a reference that we can use below to talk to selectedTab within the appSession.
        @Bindable var session = appSession
        TabView(selection: $session.selectedTab) {

            Tab("Focus", systemImage: "book.badge.plus", value: AppTab.focus, role: .search) {
                NavigationStack {
                    FocusSessionScreen(vm: tracking)
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
//		.onChange(of: appSession.selectedTab) { oldValue, newValue in
//			tabViewLogger.log("Moved from \(String(describing: oldValue)) to \(String(describing: newValue))")
//		}
    }
}

#Preview {
	MainTabView(tracking: StudyTrackingViewModel())
		.environment(AppSession())
		.modelContainer(
			for: [Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self, RemoteUser.self],
			inMemory: true
		)
}
