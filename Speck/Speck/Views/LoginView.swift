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

    @AppStorage("username") private var username = ""
    @AppStorage("password") private var password = ""  // TODO: insecure!
    @State private var error: LoginError?
    @State private var isLoading = false

    func login() {
        Task {
            isLoading = true
            do {
                try await self.spotify.login(username: username, password: password)
            } catch let e as LoginError {
                self.error = e
                isLoading = false  // TODO `defer` ?
                return
            }
            isLoading = false

            dismiss()
        }
    }

    var body: some View {
        GroupBox(label: Label("Sign in to Spotify", systemImage: "person.badge.key")) {
            VStack {
                TextField(
                    "User name",
                    text: $username
                )
                SecureField(
                    "Password",
                    text: $password
                )
                Button(action: login) {
                    Text("Login")
                }
                .disabled(isLoading)

            }
            .padding(10)
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .alert(item: $error) { error in
            Alert(
                title: Text("Error"), message: Text(error.message),
                dismissButton: .default(Text("OK")))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
