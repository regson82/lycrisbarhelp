//
//  LyricsBarApp.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//

// LyricsBarApp.swift
// Main entry point for the application.

import SwiftUI

@main
struct LyricsBarApp: App {
    // StateObject to hold the shared state of the entire application.
    @StateObject private var appState = AppState()
    // Delegate to manage the floating lyrics window.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The MenuBarExtra now uses a Text label to display the current lyric.
        MenuBarExtra {
            // The popover view is still the content when clicked.
            PopoverView()
                .environmentObject(appState)
                .onAppear {
                    appDelegate.appState = appState
                }
        } label: {
            // This label automatically updates when appState.menuBarLyric changes.
            Text(appState.menuBarLyric)
                .font(.system(size: 14))
        }
        .menuBarExtraStyle(.window)

        // This is a hidden window used only for the settings panel.
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
