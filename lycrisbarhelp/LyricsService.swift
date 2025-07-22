//
//  Untitled.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//

// LyricsService.swift
// Fetches lyrics by trying multiple APIs in sequence for maximum reliability.

import Foundation

// A generic protocol for any lyrics API service.
protocol LyricsAPI {
    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void)
}

class LyricsService {
    // A list of all API services to try.
    private let apiServices: [LyricsAPI] = [
        GeniusAPI(), // Use the new, more reliable Genius scraper first.
        LyricsOvhAPI(),
        SomeRandomAPI() // Added a third backup API.
    ]
    
    // The main public function.
    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void) {
        fetch(for: track, artist: artist, apiIndex: 0, completion: completion)
    }
    
    // A private recursive function to try each API one by one.
    private func fetch(for track: String, artist: String, apiIndex: Int, completion: @escaping (String?) -> Void) {
        guard apiIndex < apiServices.count else {
            print("All APIs failed. Could not find lyrics.")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let currentAPI = apiServices[apiIndex]
        print("--- Trying API: \(type(of: currentAPI)) ---")
        
        currentAPI.fetchLyrics(for: track, artist: artist) { [weak self] lyrics in
            if let lyrics = lyrics, !lyrics.isEmpty {
                print("Success with API: \(type(of: currentAPI))")
                DispatchQueue.main.async { completion(lyrics) }
            } else {
                print("Failed with API: \(type(of: currentAPI)). Trying next...")
                self?.fetch(for: track, artist: artist, apiIndex: apiIndex + 1, completion: completion)
            }
        }
    }
}

// MARK: - API Implementations

// New, more reliable scraper for Genius.com
struct GeniusAPI: LyricsAPI {
    
    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void) {
        let query = "\(artist) \(track)"
        guard let searchURL = createSearchURL(for: query) else { return completion(nil) }
        
        // Step 1: Search Genius to find the song's URL.
        URLSession.shared.dataTask(with: searchURL) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return completion(nil) }
            
            guard let songURL = findFirstSongURL(in: html) else {
                print("GeniusAPI: Could not find song URL in search results.")
                return completion(nil)
            }
            
            // Step 2: Fetch the song page and parse the lyrics.
            URLSession.shared.dataTask(with: songURL) { data, _, _ in
                guard let data = data, let songHTML = String(data: data, encoding: .utf8) else { return completion(nil) }
                
                let lyrics = parseLyrics(from: songHTML)
                completion(lyrics)
            }.resume()
        }.resume()
    }
    
    private func createSearchURL(for query: String) -> URL? {
        var components = URLComponents(string: "https://genius.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url
    }
    
    private func findFirstSongURL(in html: String) -> URL? {
        let pattern = #"href="(https:\/\/genius\.com\/[\w\-]+\-lyrics)""#
        if let range = html.range(of: pattern, options: .regularExpression),
           let url = URL(string: String(html[range].dropFirst(6).dropLast(1))) {
            return url
        }
        return nil
    }
    
    private func parseLyrics(from html: String) -> String? {
        // Genius puts lyrics in a container with a specific data attribute.
        let pattern = #"(?s)<div data-lyrics-container="true".*?>(.*?)</div>"#
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            print("GeniusAPI: Could not find lyrics container.")
            return nil
        }
        
        var lyricsHTML = String(html[range])
        // Clean up the HTML: replace <br> with newlines and remove all other tags.
        lyricsHTML = lyricsHTML.replacingOccurrences(of: "<br/>", with: "\n", options: .regularExpression)
        lyricsHTML = lyricsHTML.replacingOccurrences(of: "<br>", with: "\n", options: .regularExpression)
        lyricsHTML = lyricsHTML.replacingOccurrences(of: "<a.*?>(.*?)</a>", with: "$1", options: .regularExpression)
        lyricsHTML = lyricsHTML.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression)
        
        // Remove section headers like [Intro], [Verse 1], etc.
        var cleanedLyrics = lyricsHTML.replacingOccurrences(of: #"\[.*?\]"#, with: "", options: .regularExpression)
        
        // **BUG FIX**: Remove the specific "ContributorsTranslations" text.
        cleanedLyrics = cleanedLyrics.replacingOccurrences(of: #"\d+ Contributors?Translations"#, with: "", options: .regularExpression)
        
        // Trim leading/trailing whitespace and newlines.
        return cleanedLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


// API #2: lyrics.ovh
struct LyricsOvhAPI: LyricsAPI {
    private struct Response: Codable { let lyrics: String }
    
    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void) {
        let cleanTrack = track.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        let cleanArtist = artist.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        
        guard var components = URLComponents(string: "https://api.lyrics.ovh/v1/") else { return completion(nil) }
        components.path += "\(cleanArtist)/\(cleanTrack)"
        
        guard let url = components.url else { return completion(nil) }
        
        let request = URLRequest(url: url, timeoutInterval: 8.0)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return completion(nil)
            }
            
            do {
                let result = try JSONDecoder().decode(Response.self, from: data)
                let trimmedLyrics = result.lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
                var lines = trimmedLyrics.split(whereSeparator: \.isNewline).map(String.init)
                
                while let firstLine = lines.first,
                      firstLine.hasPrefix("[") || firstLine.contains("Paroles de la chanson") || firstLine.trimmingCharacters(in: .whitespaces).isEmpty {
                    lines.removeFirst()
                }
                
                completion(lines.joined(separator: "\n"))
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

// API #3: some-random-api.com
struct SomeRandomAPI: LyricsAPI {
    private struct Response: Codable { let lyrics: String }

    func fetchLyrics(for track: String, artist: String, completion: @escaping (String?) -> Void) {
        let cleanTrack = track.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        let cleanArtist = artist.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
        
        let query = "\(cleanArtist) \(cleanTrack)"
        
        guard var components = URLComponents(string: "https://some-random-api.com/lyrics") else { return completion(nil) }
        components.queryItems = [URLQueryItem(name: "title", value: query)]
        
        guard let url = components.url else { return completion(nil) }
        
        let request = URLRequest(url: url, timeoutInterval: 8.0)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return completion(nil)
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let _ = json["error"] {
                return completion(nil)
            }
            
            let result = try? JSONDecoder().decode(Response.self, from: data)
            completion(result?.lyrics)
        }.resume()
    }
}
