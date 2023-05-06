//
//  SavedTracks.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import Combine
import SpotifyWebAPI
import SwiftUI

extension SavedTrack: Identifiable {
    public var id: String { item.id! }
}

struct SavedTracks: View {
    @State private var searchCancellable: AnyCancellable? = nil
    @EnvironmentObject var spotify: Spotify

    @State private var items: [SavedTrack] = []
    @State private var itemCount: Int?
    @State private var selection: SavedTrack.ID?

    static let perPage = 50
    @State private var currentPage: Int = 0

    func fetchMore() {
        if self.searchCancellable != nil {
            debugPrint("Attempted to fetch more while already fetching, abort!")
            return
        }
        if itemCount != nil,
            currentPage * SavedTracks.perPage >= itemCount ?? 0 {
            // final page reached
            return
        }
        
        self.searchCancellable = self.spotify.api?.currentUserSavedTracks(
            limit: SavedTracks.perPage, offset: currentPage * SavedTracks.perPage
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                print(completion)
            },
            receiveValue: { response in
                self.items.append(contentsOf: response.items)
                self.itemCount = response.total
                self.currentPage += 1
                self.searchCancellable = nil
            })
    }

    var body: some View {
        Table(items, selection: $selection) {
            TableColumn("") { track in
                AsyncImage(url: track.item.album?.images?.first?.url) { image in
                    image.resizable()
                } placeholder: {
                    Placeholder()
                }
                .frame(width: 32, height: 32)
            }
            .width(32)
            TableColumn("Title") { track in
                VStack (alignment: .leading) {
                    Text(track.item.name)
                    ArtistsLabel(artists: track.item.artists).foregroundColor(.secondary)
                }
                .onAppear {
                    // TODO this logic doesn't really pertain to this column itself perse but can't find a better place
                    if track.id == items.last?.id {
                        fetchMore()
                    }
                }
            }
            TableColumn("Album") { track in
                Text(track.item.album?.name ?? "")
            }
            TableColumn("Duration") { track in
                Text(track.item.durationFormatted)
            }
        }
        .onDoubleClick {
            let item = items.first { $0.id == selection }
            guard let item = item else {
                return
            }
            spotify.player?.loadTrack(id: item.id)
        }
        .navigationTitle("Saved tracks")
        .navigationSubtitle(Text("\(itemCount ?? 0) total"))
        .onAppear {
            if spotify.isAuthorized {
                fetchMore()
            }
        }
    }
}

struct SavedTracks_Previews: PreviewProvider {
    static var previews: some View {
        SavedTracks()
    }
}
