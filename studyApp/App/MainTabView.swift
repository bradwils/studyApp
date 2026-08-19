import SwiftUI

struct MainTabView: View {
	
    var body: some View {
        TabView {

            Tab("Focus", systemImage: "book.badge.plus", role: .search) {
                NavigationStack {
                    StudyTrackingView()
                }
            }
            
            Tab("Debug", systemImage: "exclamationmark.triangle.fill") {
                NavigationStack {
                    SettingsView()
                }
            }
            
            Tab("Social", systemImage: "figure.2") {
                NavigationStack {
                    SocialView()
                }
            }
            
            Tab("Groups", systemImage: "person.3.fill") {
                NavigationStack {
                    GroupsView()
                }
            }
            
            Tab("Sessions", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    SessionsView()
                }
            }
			Tab("master [CI/CD]", systemImage: "number") {
				NavigationStack {
					Text("master [CI/CD]")
				}
			}
        }
    }
}

#Preview {
	MainTabView()
}
