//
//  ArtistView.swift
//  Speck
//
//  Created by Jari on 06/05/2023.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct ArtistView: View {
    @State var artist: Artist
    @EnvironmentObject var spotify: Spotify
    
    @State private var artistInfoCancellable: AnyCancellable? = nil
    
    func fetchArtistInfo () {
        debugPrint(artist)
        artistInfoCancellable =  spotify.api?.artist(artist.uri!)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                debugPrint(completion)
            }, receiveValue: { artist in
                debugPrint(artist)
                self.artist = artist
            })
            
    }
    
    var body: some View {
        Text(artist.name)
            .onAppear {
                fetchArtistInfo()
            }
            .navigationTitle(artist.name)
            .presentedWindowToolbarStyle(.expanded)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    AsyncImage(
                        url: artist.images?.last?.url
                    ) { image in
                        image.resizable()
                    } placeholder: {
                        PlaceholderView()
                    }
                    .clipShape(Circle())
                    .frame(width: 32, height: 32)
                }
                
            }
    }
}

struct ArtistView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistView(artist: Artist(name: "Bonobo"))
            .environmentObject(Spotify(initializeCore: false))
    }
}