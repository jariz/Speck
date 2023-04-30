//
//  Spotify.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import Foundation
import SpotifyWebAPI

struct LoginError: Identifiable, Error {
    var id: String { message }
    let message: String
}

// higher level generic wrapper for usage in our views
final class Spotify: ObservableObject {
    @Published var isAuthorized = false
    
    var core: SpeckCore
    var api: SpotifyAPI<SpeckAuthManager>?
    
    init () {
        self.core = SpeckCore()
    }
    
//    func attemptLoginFromKeychain () {
//
//    }
    
    func login (username: String, password: String) async throws {
        let result = await self.core.login(username, password)
        if !result.ok {
            throw LoginError(message: result.message.toString())
        }
        await MainActor.run {
            self.isAuthorized = true
        }
        
        let token = await self.core.get_token()
        
        self.api = SpotifyAPI(authorizationManager: SpeckAuthManager(accessToken: token.access_token.toString(), expirationDate: SpeckAuthManager.dateFromSeconds(seconds: token.expires_in), core: self.core))
    }
    
}
