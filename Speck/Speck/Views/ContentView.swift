//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import Combine
import SpotifyWebAPI
import SwiftUI

enum DetailPage {
    case savedTracks
    case library
}

struct ContentView: View {
    @EnvironmentObject var spotify: Spotify
    @State private var selection: DetailPage? = .savedTracks

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            NavigationStack {
                VStack {
                    if selection == .savedTracks {
                        SavedTracks()
                    }

                    if let player = spotify.player {
                        PlayerView()
                            .environmentObject(player)
                            .transition(.slide)
                    }
                }
            }
        }
        .sheet(
            isPresented: !$spotify.isAuthorized,
            content: {
                LoginView()
                    .environmentObject(spotify)
            })
    }
}

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
