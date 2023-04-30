//
//  SavedTracks.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import SwiftUI
import Combine
import SpotifyWebAPI

extension SavedTrack: Identifiable {
    public var id: String { item.id.unsafelyUnwrapped }
}

struct SavedTracks: View {
    @State private var searchCancellable: AnyCancellable? = nil
    @EnvironmentObject var spotify: Spotify
    
    @State private var items: [SavedTrack] = []
    @State private var selection = Set<SavedTrack.ID>()
    @State var sortOrder: [KeyPathComparator<SavedTrack>] = [
//        .init(\.item.name, order: SortOrder.forward)
    ]
    
    var body: some View {
        Table(selection: $selection, sortOrder: $sortOrder, columns: {
            TableColumn("Name", value: \.item.name)
        }, rows: {
            ForEach(items) { item in
                TableRow(item)
            }
        })
        .navigationTitle("Saved tracks")
        .onChange(of: selection, perform: { newValue in
            let selected = newValue.first
            let item = items.first { $0.id == selected }
            guard let item = item else  {
                return
            }
            spotify.core.load(item.id)
        })
        .onAppear {
            if spotify.isAuthorized {
                self.spotify.core.init_player()
                
                self.searchCancellable = self.spotify.api?.currentUserSavedTracks()
                    .receive(on: RunLoop.main)
                    .sink(receiveCompletion: { completion in
                        print(completion)
                }, receiveValue: { response in
                    self.items = response.items
                })
            }
        }
    }
}

struct SavedTracks_Previews: PreviewProvider {
    static var previews: some View {
        SavedTracks()
    }
}
