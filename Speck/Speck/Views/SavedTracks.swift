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

extension Track {
    public var durationFormatted: String {
        guard let durationMS = self.durationMS else { return "" }
        let interval = TimeInterval(durationMS / 1000)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? ""
    }
}

struct SavedTracks: View {
    @State private var searchCancellable: AnyCancellable? = nil
    @EnvironmentObject var spotify: Spotify
    
    @State private var items: [SavedTrack] = []
    @State private var itemCount: Int?
    @State private var selection = Set<SavedTrack.ID>()
    
    var body: some View {
        Table(items, selection: $selection) {
            TableColumn("Name", value: \.item.name)
            TableColumn("Artist") { item in
                Text(item.item.artists?.map({ artist in
                    artist.name
                }).joined(separator: ", ") ?? "")
            }
            TableColumn("Album") { item in
                Text(item.item.album?.name ?? "")
            }
            TableColumn("Duration") { item in
                Text(item.item.durationFormatted)
            }
       }
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
                    self.itemCount = response.total
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
