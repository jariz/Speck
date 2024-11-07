//
//  Navigator.swift
//  Speck
//
//  Created by Jari on 07/11/2024.
//

import SwiftUI

// this is my take on navigationstack that fits my needs a bit more

struct NavigatorView: View {
    @EnvironmentObject var navigation: Navigation
    
    @ViewBuilder
    var activeView: some View {
        if let last = navigation.path.last {
            switch last {
            case .savedTracks:
                SavedTracksView()
            case .library:
                Text("Library")
            case .playlist(let playlist):
                Text("Playlist \(playlist.name)")
            case .artist(let artist):
                ArtistView(artist: artist)
            }
        }
    }
    
    var body: some View {
        activeView
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    if navigation.path.count > 1 {
                        Button {
                            navigation.pop()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
            }
    }
}
