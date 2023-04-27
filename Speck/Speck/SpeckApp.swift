//
//  SpeckApp.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI

@main
struct SpeckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(RustAppWrapper(rust: Speck()))
        }
    }
}

class RustAppWrapper: ObservableObject {
    var rust: Speck

    init (rust: Speck) {
        self.rust = rust
    }
}
