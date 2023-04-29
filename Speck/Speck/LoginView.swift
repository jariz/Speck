//
//  LoginView.swift
//  Speck
//
//  Created by Jari on 28/04/2023.
//

import SwiftUI

struct LoginError: Identifiable {
    var id: String { message }
    let message: String
}

struct LoginView: View {
    @EnvironmentObject var rustApp: RustAppWrapper
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var error: LoginError?
    @State private var isLoading = false
    
    func login () {
        Task {
            isLoading = true
            let result = await rustApp.rust.login(username, password)
            isLoading = false
            if !result.ok {
                error = LoginError(message: result.message.toString())
                return
            }
            dismiss()
        }
    }
    
    var body: some View {
        GroupBox (label: Label("Sign in to Spotify", systemImage: "person.badge.key")) {
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
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
