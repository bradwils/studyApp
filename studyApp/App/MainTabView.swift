import SwiftUI

struct MainTabView: View {
    @StateObject private var subjectStore = SubjectStore()
    
    var body: some View {
        TabView {
            NavigationStack {
                SocialView()
            }
            .tabItem {
                Label("Social", systemImage: "figure.2")
            }
            
            NavigationStack {
                FocusView()
            }
            .tabItem {
                Label("Focus", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                GroupsView()
            }
            .tabItem {
                Label("Groups", systemImage: "person.3.fill")
            }
            
            NavigationStack {
                ModesView()
            }
            .tabItem {
                Label("Modes", systemImage: "ellipsis.circle")
            }
            
            
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
