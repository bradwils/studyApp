import SwiftUI

struct MainTabView: View {
    @StateObject private var subjectStore = SubjectStore()  // Create the store here
    //i should move this somewhere else
    
    var body: some View {
        TabView {
            NavigationStack {
                // Root of the social experience; links into the profile detail screen.
                SocialView()
            }
            .tabItem {
                Label("Social", systemImage: "figure.2")
            }
            
            NavigationStack {
                // Placeholder focus tools live here; replace with actual focus flows.
                FocusView()
            }
            .tabItem {
                Label("Focus", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                // Entry point for collaboration features such as study groups.
                GroupsView()
            }
            .tabItem {
                Label("Groups", systemImage: "person.3.fill")
            }
            
            NavigationStack {
                // Hosts additional study modes configuration once implemented.
                ModesView()
            }
            .tabItem {
                Label("Modes", systemImage: "ellipsis.circle")
            }
            
            
        }
    }
}

//SubjectsView(store: subjectStore)  // Pass manually


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
