//
//  CS2GameApp.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

// CS2GameApp.swift (or your app's main file)
import SwiftUI

/// Entry point of the application. The `@main` attribute tells SwiftUI where the app starts.
@main
struct CS2GameApp: App {
    /// Defines the scenes (windows) for the app. Here we provide a single window.
    var body: some Scene {
        WindowGroup {
            // The initial view presented to the user is the game menu.
            GameMenuView()   // ⬅️ Start at the menu
        }
    }
}
