//
//  NowPlaying.swift
//  Speck
//
//  Created by Jari on 03/05/2023.
//

import SpotifyWebAPI
import SwiftUI

struct NowPlayingView: View {
    var track: Track

    var body: some View {
        VStack {
            HStack {
                AsyncImage(
                    url:
                        // TODO find smallest image
                        track.album?.images?.first?.url
                ) { image in
                    image.resizable()
                } placeholder: {
                    PlaceholderView()
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading) {
                    Text(track.name).lineLimit(1, reservesSpace: true)
                    ArtistsLabel(artists: track.artists).foregroundColor(.secondary).lineLimit(
                        1, reservesSpace: true)
                }
            }
            .frame(minWidth: 200, maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NowPlaying_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView(
            track: Track(
                name: "JUGGERNAUT",
                album: Album(
                    name: "CALL ME IF YOU GET LOST",
                    images: [
                        SpotifyImage(
                            url: URL(
                                string:
                                    "https://i.scdn.co/image/ab67616d0000b273aa95a399fd30fbb4f6f59fca"
                            )!)
                    ]),
                artists: [
                    Artist(name: "Tyler, The Creator", id: "a"),
                    Artist(name: "Lil Uzi Vert", id: "b"),
                    Artist(name: "Pharell Williams", id: "c")
                ], isLocal: false, isExplicit: true)
        )
    }
}
