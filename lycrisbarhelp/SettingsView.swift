//
//  SettingsView.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//
// SettingsView.swift
// The UI for the settings panel.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            // Section for Display settings
            VStack(alignment: .leading) {
                Text("Display")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Divider()
                
                Toggle(isOn: $appState.showFloatingWindow) {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.title2)
                            .frame(width: 30)
                        Text("Show Floating Lyrics")
                    }
                }
                .toggleStyle(.switch)
            }
            
            // Section for Styling
            VStack(alignment: .leading) {
                Text("Style")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Divider()
                
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text("Highlight Intensity")
                        Slider(value: $appState.glassHighlightIntensity, in: 0.0...1.0)
                        Text("Adjust the 'shininess' of the glass text effect.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section for Animation
            VStack(alignment: .leading) {
                Text("Animation")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Divider()
                
                Picker("Transition Style", selection: $appState.animationType) {
                    ForEach(LyricAnimationType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Section for Timing
            VStack(alignment: .leading) {
                Text("Timing")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Divider()
                
                Toggle(isOn: $appState.useAutomaticScrolling) {
                    HStack {
                        Image(systemName: "music.note.tv")
                            .font(.title2)
                            .frame(width: 30)
                        Text("Sync with Song Progress")
                    }
                }
                .toggleStyle(.switch)
                
                HStack {
                    Image(systemName: "timer")
                        .font(.title2)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text("Manual Scroll Speed")
                        Slider(value: $appState.lyricCycleDelay, in: 1.0...10.0, step: 0.5)
                            .onChange(of: appState.lyricCycleDelay) { _ in
                                appState.restartLyricTimer()
                            }
                        Text(String(format: "%.1f seconds delay", appState.lyricCycleDelay))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(appState.useAutomaticScrolling) // Disable if auto-sync is on.
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 400, height: 500)
    }
}
