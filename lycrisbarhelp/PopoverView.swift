//
//  PopoverView.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//

// PopoverView.swift
// The UI for the main popover window.

import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(.pink)
                Text("LyricsBar")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // MARK: - Current Song Info
            VStack {
                Text(appState.currentTrack)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(appState.currentArtist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // MARK: - Lyrics Display
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if appState.lyrics.isEmpty {
                        Text("...")
                            .foregroundColor(.secondary)
                    } else {
                        // The lyrics are now tappable to sync.
                        ForEach(Array(appState.lyrics.enumerated()), id: \.offset) { index, line in
                            Button(action: {
                                // Manually sync to the clicked line.
                                appState.syncLyric(to: index)
                            }) {
                                Text(line)
                                    .fontWeight(index == appState.currentLyricLine ? .bold : .regular)
                                    .foregroundColor(index == appState.currentLyricLine ? appState.lyricColor : .primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle()) // Makes the text look like normal text.
                        }
                    }
                }
                .padding()
            }
            .frame(width: 300, height: 350)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)

            Divider()

            // MARK: - Footer Controls
            HStack {
                SettingsLink {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 320)
    }
}
