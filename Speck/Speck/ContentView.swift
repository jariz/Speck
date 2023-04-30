//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct ContentView: View {
    @EnvironmentObject var rustApp: RustAppWrapper
    @State var presentLoginSheet = true
    
    @State var client: SpotifyAPI<SpeckAuthManager>?
    @State private var searchCancellable: AnyCancellable? = nil
    
    var body: some View {
        VStack {
            Button("hello") {
                
            }
        }
        .sheet(isPresented: $presentLoginSheet, content: {
            LoginView()
                .environmentObject(rustApp)
        })
        .onChange(of: presentLoginSheet) { presented in
            if !presented {
                Task {
                    print("Getting token...")
                    let token = await self.rustApp.rust.get_token()
                    self.client = SpotifyAPI(authorizationManager: SpeckAuthManager(accessToken: token.access_token.toString(), expirationDate: SpeckAuthManager.dateFromSeconds(seconds: token.expires_in), speck: self.rustApp.rust))
                    self.client?.setupDebugging()
                    self.searchCancellable = self.client?.search(query: "fort romeau", categories: [.artist])
                        .receive(on: RunLoop.main)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                    }, receiveValue: { searchResult in
                            print(searchResult.artists?.items[0].name)
                    })
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
