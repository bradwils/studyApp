import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
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
            
            Tab("Focus", systemImage: "book.badge.plus", role: .search) {
                NavigationStack {
                    StudyTrackingView()
                }
            }
            
            
            Tab("Groups", systemImage: "person.3.fill") {
                NavigationStack {
                    GroupsView()
                }
            }
            
            Tab("Modes", systemImage: "ellipsis.circle") {
                NavigationStack {
                    ModesView()
                }
            }
        }

    }
    
    
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
