//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import Combine
import SwiftUI
import Inject
import SpotifyWebAPI


struct ContentView: View {
    @ObservedObject var spotify = Spotify.shared
    @ObservedObject var navigation = Navigation.shared
    
    var body: some View {
        HStack {
            NavigationSplitView {
                SidebarView()
            }
            detail: {
                NavigatorView()
            }
            .environmentObject(navigation)
            .sheet(
                isPresented: !$spotify.isAuthorized,
                content: {
                    LoginView()
                        .environmentObject(spotify)
                })
            .enableInjection()
            
            if let player = spotify.player {
                LyricsView()
                    .environmentObject(player)
            }
        }
        
        if let player = spotify.player {
            PlayerView()
                .environmentObject(player)
                .transition(.slide)
        }
    }
    
    @ObserveInjection var inject
}

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}
