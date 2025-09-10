//
//  CS2GameApp.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

// CS2GameApp.swift (or your app's main file)
import SwiftUI

/// Entry point of the application.
@main
struct CS2GameApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppRootView()
                    .toolbarBackground(Theme.bg, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}

