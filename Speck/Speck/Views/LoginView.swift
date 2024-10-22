//
//  LoginView.swift
//  Speck
//
//  Created by Jari on 28/04/2023.
//

import SpotifyWebAPI
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var spotify: Spotify
    @Environment(\.dismiss) private var dismiss

    @State private var error: IdentifiableError?
    @State private var isLoading = true
    @State private var isAuthenticating = false
    
    var loginWhenAppearing = false
    
    init (loginWhenAppearing: Bool = true) {
        self.loginWhenAppearing = loginWhenAppearing
    }

    var body: some View {
        VStack {
            ProgressView()
            Text("Signing in...").font(.largeTitle)
            if isAuthenticating {
                Text("A page was opened in your browser.").foregroundStyle(.secondary).padding(.top, 10)
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .alert(item: $error) { error in
            Alert(
                title: Text("Error"), message: Text(error.id),
                dismissButton: .default(Text("OK")))
        }
        .onAppear {
            Task {
                do {
                    if !spotify.isAuthorized {
                        self.isAuthenticating = true
                        try await spotify.authorize()
                    }
                } catch {
                    self.error = IdentifiableError(error: error)
                }
            }
        }
    }
}

struct IdentifiableError: Identifiable {
    let id: String
    let error: Error
    
    init(error: Error) {
        self.error = error
        self.id = error.localizedDescription
    }
}
