//
//  ContentView.swift
//  Speck
//
//  Created by Jari on 26/04/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var rustApp: RustAppWrapper
    @State var presentLoginSheet = true
    
    var body: some View {
        VStack {
            Button("hello") {
                
            }
        }
        .sheet(isPresented: $presentLoginSheet, content: {
            LoginView()
                .environmentObject(rustApp)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
