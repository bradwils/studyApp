//
//  StudyAppWidgets.swift
//  studyApp
//
//  Widget bundle for registering all widgets including Live Activities
//

import WidgetKit
import SwiftUI

/// Widget bundle that registers all widgets for the app
/// This allows the system to discover and display widgets and Live Activities
/// Note: For Live Activities embedded in the main app (not a separate extension),
/// you don't need @main here - the Live Activity is automatically available.
struct StudyAppWidgets: WidgetBundle {
    var body: some Widget {
        StudySessionLiveActivity()
    }
}
