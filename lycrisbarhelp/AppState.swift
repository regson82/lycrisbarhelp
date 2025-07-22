//
//  AppState.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//
// AppState.swift
// A single source of truth for the application's state.

import SwiftUI
import Combine

// This extension is moved to the top to resolve a potential compiler issue.
extension Notification.Name {
    static let toggleFloatingWindow = Notification.Name("toggleFloatingWindow")
}

// Enum for different lyric animation styles.
enum LyricAnimationType: String, CaseIterable, Identifiable {
    case slide = "Slide"
    case fade = "Fade"
    case scale = "Scale"
    var id: Self { self }
}

class AppState: ObservableObject {
    // MARK: - Song Information
    @Published var currentTrack: String = "Nothing Playing"
    @Published var currentArtist: String = "..."
    @Published var lyrics: [String] = ["..."]
    @Published var currentLyricLine: Int = 0 {
        didSet {
            updateMenuBarLyric()
        }
    }
    
    @Published var menuBarLyric: String = "LyricsBar"

    // MARK: - User Settings
    @Published var showFloatingWindow: Bool = false { // Changed to false by default
        didSet {
            NotificationCenter.default.post(name: .toggleFloatingWindow, object: nil)
        }
    }
    
    @Published var animationType: LyricAnimationType = .slide
    @Published var useAutomaticScrolling: Bool = true {
        didSet {
            if useAutomaticScrolling {
                restartLyricTimer()
            } else {
                stopLyricCycling()
            }
        }
    }
    @Published var lyricCycleDelay: Double = 3.0 // Now used for manual mode only
    
    @Published var glassHighlightIntensity: Double = 0.7
    
    @Published var launchAtLogin: Bool = false

    // MARK: - Services
    private let spotifyService = SpotifyService()
    private let appleMusicService = AppleMusicService()
    private let lyricsService = LyricsService()
    private var songCheckTimer: Timer?
    private var lyricCycleTimer: Timer?

    init() {
        // The timer now runs more frequently for smoother syncing.
        songCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.fetchCurrentSongFromMusicPlayers()
        }
        fetchCurrentSongFromMusicPlayers()
    }

    func fetchCurrentSongFromMusicPlayers() {
        spotifyService.getCurrentTrack { [weak self] (track, artist, duration, position) in
            guard let self = self else { return }
            
            // **BUG FIX**: The check for valid data was too strict. Now only track and artist are required.
            if let track = track, let artist = artist {
                self.updateSong(track: track, artist: "\(artist) (Spotify)", duration: duration, position: position)
            } else {
                self.appleMusicService.getCurrentTrack { (musicTrack, musicArtist, musicDuration, musicPosition) in
                    if let musicTrack = musicTrack, let musicArtist = musicArtist {
                        self.updateSong(track: musicTrack, artist: "\(musicArtist) (Apple Music)", duration: musicDuration, position: musicPosition)
                    } else {
                        self.updateSong(track: nil, artist: nil, duration: nil, position: nil)
                    }
                }
            }
        }
    }
    
    private func updateSong(track: String?, artist: String?, duration: Double?, position: Double?) {
        DispatchQueue.main.async {
            // Case 1: A song is playing.
            if let track = track, let artist = artist {
                // If it's a new song, fetch lyrics.
                if self.currentTrack != track {
                    self.currentTrack = track
                    self.currentArtist = artist
                    self.lyrics = ["Fetching lyrics..."]
                    self.fetchLyricsForCurrentSong()
                }
                // If it's the same song, just update the progress.
                else if let duration = duration, let position = position, self.useAutomaticScrolling {
                    self.syncLyricToPosition(position: position, duration: duration)
                }
            }
            // Case 2: Nothing is playing.
            else {
                if self.currentTrack != "Nothing Playing" {
                    self.currentTrack = "Nothing Playing"
                    self.currentArtist = "..."
                    self.lyrics = ["..."]
                    self.stopLyricCycling()
                    self.updateMenuBarLyric()
                }
            }
        }
    }

    func fetchLyricsForCurrentSong() {
        lyricsService.fetchLyrics(for: currentTrack, artist: currentArtist) { [weak self] (fetchedLyrics: String?) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let fetchedLyrics = fetchedLyrics, !fetchedLyrics.isEmpty {
                    self.lyrics = fetchedLyrics.split(separator: "\n").map(String.init)
                    self.currentLyricLine = 0
                } else {
                    self.lyrics = ["Could not find lyrics for this song."]
                }
                self.updateMenuBarLyric()
            }
        }
    }
    
    // This function is now only used for manual mode.
    func startLyricCycling(fromBeginning: Bool) {
        stopLyricCycling()
        if fromBeginning { currentLyricLine = 0 }
        
        lyricCycleTimer = Timer.scheduledTimer(withTimeInterval: self.lyricCycleDelay, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if !self.lyrics.isEmpty {
                       self.currentLyricLine = (self.currentLyricLine + 1) % self.lyrics.count
                    }
                }
            }
        }
    }
    
    // New function for true automatic syncing.
    func syncLyricToPosition(position: Double, duration: Double) {
        guard !lyrics.isEmpty, lyrics.count > 1, duration > 0 else { return }
        
        // Calculate which line should be showing based on progress.
        let progress = position / duration
        let targetLine = Int(progress * Double(lyrics.count))
        
        if targetLine != self.currentLyricLine {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.currentLyricLine = targetLine
            }
        }
    }

    func stopLyricCycling() {
        lyricCycleTimer?.invalidate()
        lyricCycleTimer = nil
    }
    
    func restartLyricTimer() {
        if !useAutomaticScrolling && !lyrics.isEmpty && lyrics != ["..."] {
            startLyricCycling(fromBeginning: false)
        }
    }
    
    func syncLyric(to line: Int) {
        self.useAutomaticScrolling = false // Clicking a line disables auto-sync.
        stopLyricCycling()
        self.currentLyricLine = line
    }
    
    private func updateMenuBarLyric() {
        if lyrics.indices.contains(currentLyricLine) {
            let line = lyrics[currentLyricLine]
            if line.count > 50 {
                self.menuBarLyric = String(line.prefix(50)) + "..."
            } else {
                self.menuBarLyric = line
            }
        } else {
            self.menuBarLyric = "LyricsBar"
        }
    }
}
