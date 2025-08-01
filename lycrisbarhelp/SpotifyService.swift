//
//  SpotifyService.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//
// SpotifyService.swift
// Handles communication with the Spotify desktop app via AppleScript.

import Foundation

class SpotifyService {
    // Updated script to get track name, artist, duration, and current position.
    private let scriptSource = """
    if application "Spotify" is running then
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set trackDuration to duration of current track / 1000.0
                set playerPosition to player position
                return trackName & "|||" & artistName & "|||" & trackDuration & "|||" & playerPosition
            else
                return ""
            end if
        end tell
    else
        return ""
    end if
    """

    // The completion handler now returns more data.
    func getCurrentTrack(completion: @escaping (String?, String?, Double?, Double?) -> Void) {
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let output = script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
                completion(nil, nil, nil, nil)
                return
            }
            
            if let resultString = output.stringValue, !resultString.isEmpty {
                let components = resultString.components(separatedBy: "|||")
                if components.count == 4,
                   let duration = Double(components[2]),
                   let position = Double(components[3]) {
                    completion(components[0], components[1], duration, position)
                } else {
                    completion(nil, nil, nil, nil)
                }
            } else {
                completion(nil, nil, nil, nil)
            }
        }
    }
}
