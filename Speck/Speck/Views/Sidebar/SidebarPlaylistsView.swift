//
//  Playlists.swift
//  Speck
//
//  Created by Jari on 24/10/2024.
//

import Combine
import SpotifyWebAPI
import Swift
import SwiftUI

struct SidebarPlaylistsView: View {
    @State var playlists: [Playlist<PlaylistItemsReference>] = []

    func fetchPlaylists() {
        Spotify.shared.api
            .currentUserPlaylists()
            .receive(on: RunLoop.main)
            .sink { _ in
                debugPrint("playlists retrieved")
            } receiveValue: { response in
                playlists = response.items
            }
            .store(in: &cancellables)
    }

    @State var cancellables: [AnyCancellable] = []

    var body: some View {
        Group {
            Section(header: Text("Playlists")) {
                ForEach(playlists, id: \.self) { playlist in
                    NavigationLink("\(playlist.name)", value: DetailPage.playlist(playlist))
                }
            }
        }
        .task {
            fetchPlaylists()
        }
    }
}
