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
    
    var loginWhenAppearing = false
    
    init (loginWhenAppearing: Bool = true) {
        self.loginWhenAppearing = loginWhenAppearing
    }

    var body: some View {
        VStack {
            ProgressView()
            Text("Signing in...").font(.largeTitle).padding(.bottom, 10)
            Text("A page was opened in your browser.").foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .alert(item: $error) { error in
            Alert(
                title: Text("Error"), message: Text(error.id),
                dismissButton: .default(Text("OK")))
        }
        .onAppear {
            startAuthentication()
        }
    }
    
    func startAuthentication () {
        spotify.getAccessToken { result in
            switch result {
                case .success:
                dismiss()
                break;
            case .failure(let error):
                self.error = IdentifiableError(error: error)
                isLoading = false
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(Spotify(initializeCore: false))
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
