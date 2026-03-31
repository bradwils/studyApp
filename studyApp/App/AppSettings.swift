import SwiftUI
import SwiftData
struct AppSettings {
    
    //default themes

    
    //initialise and append themes
    var themesArray: [AppTheme] = []
    
    //initializer to set up default themes
    init() { //when created, update default values
        
        //MARK: Themes
    
        themesArray = defaultThemes
        
//        getUserThemesFromStorage() -> ? {
        
//    }
    }
    
    

    


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: Themes

    let defaultThemes: [AppTheme] = [
        AppTheme(name: "Default", primary: .white, secondary: .blue, accent: .gray)
    ]
    
    
}


// New SwiftUI view for the settings UI

struct AppSettingsView: View {
    @Environment(\.modelContext) var context //our swiftdata connection
    @State private var selectedColor: Color = .white
    @State private var settings = AppSettings()
    
    
    /// All persisted `AppTheme` records, automatically kept in sync by SwiftData.
    @Query var themes: [AppTheme]

    var body: some View {
        VStack {
            ColorPicker("Background", selection: $selectedColor)
            Text("Create a new theme")
            Button("Create Summer Theme") {
                let newTheme = AppTheme(name: "Summer", primary: selectedColor, secondary: .orange, accent: .red)
                context.insert(newTheme)

            }
            Button("Create Winter Theme") {
                let newTheme = AppTheme(name: "Winter", primary: selectedColor, secondary: .blue, accent: .white)
                context.insert(newTheme)

            }
            Button("Create dummy") {
                let newTheme = AppTheme(name: "Dummy", primary: selectedColor, secondary: .green, accent: .blue)
                context.insert(newTheme)
            }
        }
        
        VStack {
            ForEach(themes) { theme in
                Text(theme.name)
                    .foregroundColor(theme.primaryColor)
            }
        }
        
    }
}



//MARK: Theme Helpers




//MARK: Preview
// `.modelContainer` is only needed here for Xcode Previews.
// In production the container is attached at the app root (StudyAppApp).
#Preview {
    AppSettingsView()
        .modelContainer(for: AppTheme.self, inMemory: true)

}
