//
//  LoginView.swift
//  Speck
//
//  Created by Jari on 28/04/2023.
//

import SpotifyWebAPI
import SwiftUI

struct LoginView: View {
    @ObservedObject var spotify = Spotify.shared
    @Environment(\.dismiss) private var dismiss

    @State private var error: Error?
    @State private var isAuthenticating = false

    var body: some View {
        VStack {
            ProgressView()
            if let error = error {
                Text("An error occured.").font(.largeTitle)
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text("\(error.localizedDescription)")
                        .foregroundColor(.red)
                        .foregroundStyle(.secondary)

                }.padding(.top, 10)

                Button(action: authenticate) {
                    Text("Retry")
                }
                .padding(.top, 10)
            } else {
                Text("Signing in...").font(.largeTitle)

                if isAuthenticating {
                    Text("A page was opened in your browser.").foregroundStyle(
                        .secondary
                    ).padding(.top, 10)
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)

        .onAppear {
            authenticate()
        }
    }

    func authenticate() {
        Task {
            do {
                if !spotify.isAuthorized {
                    self.isAuthenticating = true
                    try await spotify.authorize()
                }
            } catch {
                self.isAuthenticating = false
                self.error = error
            }
        }
    }
}
