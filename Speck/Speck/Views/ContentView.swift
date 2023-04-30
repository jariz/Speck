//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI
import SpotifyWebAPI
import Combine

enum DetailPage {
    case savedTracks
    case library
}

struct ContentView: View {
    @EnvironmentObject var spotify: Spotify
    @State private var selection: DetailPage? = .savedTracks
    
    var body: some View {
        VStack {
            NavigationSplitView {
                SidebarView(selection: $selection)
            } detail: {
                if selection == .savedTracks {
                    SavedTracks()
                }
            }
        }
        .sheet(isPresented: !$spotify.isAuthorized, content: {
            LoginView()
                .environmentObject(spotify)
        })
//        .onChange(of: presentLoginSheet) { presented in
//            if !presented {
//
//            }
//        }
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
