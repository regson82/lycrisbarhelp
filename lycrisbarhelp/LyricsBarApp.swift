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
        // This creates the icon in the macOS menu bar.
        MenuBarExtra("LyricsBar", systemImage: "music.note") {
            // The view that appears when the user clicks the menu bar icon.
            PopoverView()
                .environmentObject(appState) // Pass the shared state to the view.
                .onAppear {
                    // When the popover appears, link the appState to the delegate.
                    appDelegate.appState = appState
                }
        }
        .menuBarExtraStyle(.window) // Use a modern popover-style window.

        // This is a hidden window used only for the settings panel.
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
