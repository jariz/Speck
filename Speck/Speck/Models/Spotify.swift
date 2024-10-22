//
//  Spotify.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import AppKit
import Foundation
import Network
import OAuth2
import SpotifyWebAPI
import Vapor

struct LoginError: Identifiable, Error {
    var id: String { message }
    let message: String
}

let OAUTH_CLIENT_ID = "65b708073fc0480ea92a077233ca87bd"
let OAUTH_PORT = 5165
let OAUTH_SCOPES = [
    "app-remote-control",
    "playlist-modify",
    "playlist-modify-private",
    "playlist-modify-public",
    "playlist-read",
    "playlist-read-collaborative",
    "playlist-read-private",
    "streaming",
    "ugc-image-upload",
    "user-follow-modify",
    "user-follow-read",
    "user-library-modify",
    "user-library-read",
    "user-modify",
    "user-modify-playback-state",
    "user-modify-private",
    "user-personalized",
    "user-read-birthdate",
    "user-read-currently-playing",
    "user-read-email",
    "user-read-play-history",
    "user-read-playback-position",
    "user-read-playback-state",
    "user-read-private",
    "user-read-recently-played",
    "user-top-read",
]

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
    func getAccessToken(
        _ completion: @escaping (Result<String, Error>) -> Void
    ) {
        let authURLString = "https://accounts.spotify.com/authorize"
        let tokenURLString = "https://accounts.spotify.com/api/token"
        let redirectURLString = "http://127.0.0.1:\(OAUTH_PORT)/login"

        guard let redirectURL = URL(string: redirectURLString)
        else {
            completion(.failure(OAuth2Error.invalidRedirectURL("Unable to parse spotify url's")))
            return
        }

        // Configure OAuth2 client
        let client = OAuth2CodeGrant(settings: [
            "client_id": OAUTH_CLIENT_ID,
            "authorize_uri": authURLString,
            "token_uri": tokenURLString,
            "redirect_uris": [redirectURLString],
            "scope": OAUTH_SCOPES.joined(separator: " "),
            "secret_in_body": true,
            "keychain": false,
        ])

        client.authConfig.authorizeEmbedded = false
        client.authConfig.ui.useSafariView = true
        client.clientConfig.useProofKeyForCodeExchange = true

        // librespot has it's own cache for credentials
        client.useKeychain = false

        startLocalHTTPServer { result in
            switch result {
            case .success(let code):
                client.exchangeCodeForToken(code)
            case .failure(let error):
                completion(.failure(error))
            }
        }

        client.authorize { authParameters, error in
            if let accessToken = client.accessToken {

                completion(.success(accessToken))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }

    func startLocalHTTPServer(
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let app = Application()
        app.http.server.configuration.port = OAUTH_PORT

        app.get("login") { req -> String in
            DispatchQueue.main.async {
                app.server.shutdown()
            }

            completion(.success(try req.query.get(at: "code")))

            return "You can cmd+tab back to Speck and close this window."
        }

        do {
            try app.server.start()
        } catch {
            completion(.failure(error))
        }
    }
    func login(accessToken: String) async throws {
        guard let core = self.core else {
            throw LoginError(message: "Core not initialized")
        }
        let result = await core.login(accessToken)
        if !result.ok {
            throw LoginError(message: result.message.toString())
        }

        await MainActor.run {
            let api = SpotifyAPI(
                authorizationManager: SpeckAuthManager(
                    accessToken: accessToken,
                    expirationDate: SpeckAuthManager.dateFromSeconds(
                        seconds: 999999999 // err... todo?
                    ),
                    core: core
                ))
            
            self.api = api
            self.player = Player(core: core, api: api)
            self.isAuthorized = true
        }

    }

}
