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
    @EnvironmentObject var navigationModel: Navigation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(artists ?? []) { artist in
                Button {
                    navigationModel.path.append(.artist(artist))
                } label: {
                    Text(artist.name)
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
            Artist(name: "Moderat"), Artist(name: "Logic1000"), Artist(name: "Big Ever")
        ])
    }
}
