//
//  Navigation.swift
//  Speck
//
//  Created by Jari on 06/11/2024.
//
import SwiftUI
import SpotifyWebAPI

enum DetailPage: Hashable {
    case savedTracks
    case library
    case playlist(Playlist<PlaylistItemsReference>)
    case artist(Artist)
}

class Navigation: ObservableObject {
    static let shared = Navigation()

    init () {
        firstPage = path[0]
        $path
            .map { $0.first }
            .assign(to: &$firstPage)
    }

    @Published var path: [DetailPage] = [.savedTracks]

    @Published var firstPage: DetailPage? {
        didSet {
            DispatchQueue.main.async {
                self.path = [self.firstPage!]
            }
        }
    }

    func push(_ page: DetailPage) {
        path.append(page)
    }

    func replace(_ page: DetailPage) {
        path = [page]
    }

    func pop() {
        path.removeLast()
    }
}
