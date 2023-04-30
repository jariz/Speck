//
//  SpeckApp.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI
import SpotifyWebAPI

@main
struct SpeckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Spotify())
        }
    }
}
