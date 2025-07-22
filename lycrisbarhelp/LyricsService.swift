//
//  Untitled.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//
// LyricsService.swift
// Fetches lyrics by running a bundled Python script.

import Foundation

class LyricsService {
    
    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void) {
        print("--- Trying Python script for lyrics ---")
        
        guard let scriptPath = Bundle.main.path(forResource: "get_lyrics", ofType: "py") else {
            print("Error: Could not find get_lyrics.py in the app bundle.")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // Clean the artist name by removing the music player source (e.g., "(Spotify)").
        let cleanArtist = artist.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        let cleanTrack = track.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        
        let command = "python3 \"\(scriptPath)\" \"\(cleanArtist)\" \"\(cleanTrack)\""
        process.arguments = ["-c", command]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let errorOutput = String(data: errorData, encoding: .utf8)
            
            if let error = errorOutput, !error.isEmpty {
                print("Python script error: \(error)")
            }
            
            if let lyrics = output, !lyrics.isEmpty {
                print("Success with Python script.")
                DispatchQueue.main.async { completion(lyrics) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
            
        } catch {
            print("Failed to run Python script: \(error)")
            DispatchQueue.main.async { completion(nil) }
        }
    }
}
