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
    @Published var currentArtist: String = "Spotify"
    @Published var lyrics: [String] = ["..."]
    @Published var currentLyricLine: Int = 0

    // MARK: - User Settings
    @Published var showFloatingWindow: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .toggleFloatingWindow, object: nil)
        }
    }
    @Published var lyricColor: Color = .white
    
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
    @Published var lyricCycleDelay: Double = 3.0
    
    // Renamed for clarity: now controls opacity.
    @Published var glassTextOpacity: Double = 0.7
    
    @Published var launchAtLogin: Bool = false

    // MARK: - Services
    private let spotifyService = SpotifyService()
    private let lyricsService = LyricsService()
    private var cancellables = Set<AnyCancellable>()
    private var songCheckTimer: Timer?
    private var lyricCycleTimer: Timer?

    init() {
        songCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.fetchCurrentSong()
        }
        fetchCurrentSong()
    }

    func fetchCurrentSong() {
        spotifyService.getCurrentTrack { [weak self] (track: String?, artist: String?) in
            guard let self = self else { return }
            
            if let track = track, let artist = artist, self.currentTrack != track {
                DispatchQueue.main.async {
                    self.currentTrack = track
                    self.currentArtist = artist
                    self.lyrics = ["Fetching lyrics..."]
                    self.fetchLyricsForCurrentSong()
                }
            } else if track == nil {
                DispatchQueue.main.async {
                    self.currentTrack = "Nothing Playing"
                    self.currentArtist = "Spotify"
                    self.lyrics = ["..."]
                    self.stopLyricCycling()
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
                    if self.useAutomaticScrolling {
                        self.startLyricCycling(fromBeginning: true)
                    }
                } else {
                    self.lyrics = ["Could not find lyrics for this song."]
                    self.stopLyricCycling()
                }
            }
        }
    }
    
    func startLyricCycling(fromBeginning: Bool) {
        stopLyricCycling()
        
        if fromBeginning {
            currentLyricLine = 0
        }
        
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

    func stopLyricCycling() {
        lyricCycleTimer?.invalidate()
        lyricCycleTimer = nil
    }
    
    func restartLyricTimer() {
        if useAutomaticScrolling && !lyrics.isEmpty && lyrics != ["..."] {
            startLyricCycling(fromBeginning: false)
        }
    }
    
    func syncLyric(to line: Int) {
        stopLyricCycling()
        self.currentLyricLine = line
        if useAutomaticScrolling {
            restartLyricTimer()
        }
    }
}

extension Notification.Name {
    static let toggleFloatingWindow = Notification.Name("toggleFloatingWindow")
}
