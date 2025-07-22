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
    private let scriptSource = """
    if application "Spotify" is running then
        tell application "Spotify"
            if player state is playing then
                return (get name of current track) & "|||" & (get artist of current track)
            else
                return ""
            end if
        end tell
    else
        return ""
    end if
    """

    func getCurrentTrack(completion: @escaping (String?, String?) -> Void) {
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let output = script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
                completion(nil, nil)
                return
            }
            
            if let resultString = output.stringValue, !resultString.isEmpty {
                let components = resultString.components(separatedBy: "|||")
                if components.count == 2 {
                    completion(components[0], components[1])
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
}
