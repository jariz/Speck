//
//  ArtistsLabel.swift
//  Speck
//
//  Created by Jari on 02/05/2023.
//

import SpotifyWebAPI
import SwiftUI

extension Artist: Identifiable {
}

struct ArtistsLabel: View {
    var artists: [Artist]?

    var body: some View {
        //        Text(
        //            artists?.map({ artist in
        //                artist.name
        //            }).joined(separator: ", ") ?? ""
        //        )
        HStack (spacing: 0) {
            ForEach(artists ?? []) { artist in
                NavigationLink(artist.name) {
                    Text("This is artist view for \(artist.name)")
                }
                .buttonStyle(.plain)
                if artists?.last?.id != artist.id {
                    Text(", ")
                }
            }
        }
    }
}

struct ArtistsLabel_Previews: PreviewProvider {
    static var previews: some View {
        ArtistsLabel(artists: [
            Artist(name: "Moderat"), Artist(name: "Logic1000"), Artist(name: "Big Ever"),
        ])
    }
}
