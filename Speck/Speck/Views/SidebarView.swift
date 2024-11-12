//
//  SidebarView.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import SwiftUI
import SpotifyWebAPI

struct SidebarView: View {
    @EnvironmentObject var navigation: Navigation

    var body: some View {

        List(selection: $navigation.firstPage) {
            NavigationLink(value: DetailPage.savedTracks) {
                Label("Saved Tracks", systemImage: "music.note.list")
            }
            NavigationLink(value: DetailPage.library) {
                Label("Library", systemImage: "books.vertical")
            }
            SidebarPlaylistsView()
        }
//        .onChange(of: selectedPage, { oldValue, newValue in
//            navigation.replace(newValue)
//        })
        .frame(minWidth: 250)
    }
}
