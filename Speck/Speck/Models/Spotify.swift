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
    @Published var api: SpotifyAPI<SpeckAuthManager>?
    @Published var player: Player?

    private var core: SpeckCore?

    init(initializeCore: Bool = true) {
        if initializeCore {
            self.core = SpeckCore()
        }
    }

    func login(username: String, password: String) async throws {
        guard let core = self.core else {
            throw LoginError(message: "Core not initialized")
        }
        let result = await core.login(username, password)
        if !result.ok {
            throw LoginError(message: result.message.toString())
        }

        let token = await core.get_token()

        await MainActor.run {
            let api = SpotifyAPI(
                authorizationManager: SpeckAuthManager(
                    accessToken: token.access_token.toString(),
                    expirationDate: SpeckAuthManager.dateFromSeconds(seconds: token.expires_in),
                    core: core
                ))
            self.api = api

            self.isAuthorized = true
            self.api = api
            self.player = Player(core: core, api: api)
        }

    }

}
