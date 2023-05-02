//
//  SidebarView.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: DetailPage?

    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: DetailPage.savedTracks) {
                Label("Saved Tracks", systemImage: "music.note.list")
            }
            NavigationLink(value: DetailPage.library) {
                Label("Library", systemImage: "books.vertical")
            }
        }
        .frame(minWidth: 250)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selection: .constant(.savedTracks))
    }
}
