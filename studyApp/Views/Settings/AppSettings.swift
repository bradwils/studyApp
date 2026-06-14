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
