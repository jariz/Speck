//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var rustApp: RustAppWrapper
    
    func start () {
        Task {
            await rustApp.rust.start(username, password)
        }
    }
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            TextField(
                "User name",
                text: $username
            )
            SecureField(
                "Password",
                text: $password
            )
            Button(action: start) {
                Text("Login")
            }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
