//
//  Lyrics+init(for).swift
//  Speck
//
//  Created by Jari on 07/11/2024.
//
import SpotifyWebAPI

extension Lyrics {
    static func from(_ track: Track) async throws -> Lyrics? {
        guard let trackId = track.id else {
            return nil
        }

        return try await SpeckCore.shared.get_lyrics(trackId)
    }
}
