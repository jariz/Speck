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

struct SavedTracksView: View {
    @State private var searchCancellable: AnyCancellable? = nil
    @EnvironmentObject var spotify: Spotify

    @State private var items: [SavedTrack] = []
    @State private var itemCount: Int?
    @State private var selection: SavedTrack.ID?

    static let perPage = 50
    @State private var currentPage: Int = 0

    func fetchMore() {
        if searchCancellable != nil {
            debugPrint("Attempted to fetch more while already fetching, abort!")
            return
        }
        if itemCount != nil,
            currentPage * SavedTracksView.perPage >= itemCount ?? 0 {
            // final page reached
            return
        }
        
        searchCancellable = spotify.api.currentUserSavedTracks(
            limit: SavedTracksView.perPage, offset: currentPage * SavedTracksView.perPage
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                print(completion)
            },
            receiveValue: { response in
                items.append(contentsOf: response.items)
                itemCount = response.total
                currentPage += 1
                searchCancellable = nil
            })
    }

    var body: some View {
        Table(items, selection: $selection) {
            TableColumn("") { track in
                AsyncImage(url: track.item.album?.images?.first?.url) { image in
                    image.resizable()
                } placeholder: {
                    PlaceholderView()
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
                    // TODO this logic doesn't really pertain to this column itself but can't find a better place
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
        // TODO find a way to use this modifier on specific rows instead of the entire table
        .onDoubleClick {
            let item = items.first { $0.id == selection }
            guard let item = item else {
                return
            }
            spotify.player?.loadTrack(id: item.id)
        }
        .navigationTitle("Saved tracks")
        .navigationSubtitle(Text("\(itemCount ?? 0) total"))
        .onChange(of: spotify.isAuthorized) {
            if spotify.isAuthorized {
                fetchMore()
            }
        }
    }
}

struct SavedTracks_Previews: PreviewProvider {
    static var previews: some View {
        SavedTracksView()
    }
}
