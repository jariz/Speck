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

    @State private var error: LoginError?
    @State private var isLoading = false

    var body: some View {
        GroupBox(label: Label("Sign in to Spotify", systemImage: "person.badge.key")) {
            VStack {
                

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
        .onAppear {
            isLoading = true
            spotify.getAccessToken { result in
                switch result {
                    case .success:
                    isLoading = false

                    dismiss()
                    break;
                case .failure(let error):
    //                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
