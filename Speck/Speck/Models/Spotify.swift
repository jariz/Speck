//
//  Spotify.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import Foundation
import Network
import SpotifyWebAPI
import OAuth2
import AppKit

struct LoginError: Identifiable, Error {
    var id: String { message }
    let message: String
}
//
//struct OAuthToken {
//    let accessToken: String
//    let refreshToken: String
//    let expiresAt: Date
//    let tokenType: String
//    let scopes: [String]
//}
//
//enum OAuthError: Error {
//    case invalidSpotifyURI
//    case invalidRedirectURI
//    case authorizationError(String)
//    case tokenExchangeError(String)
//    case receiveError
//}

let OAUTH_CLIENT_ID = "65b708073fc0480ea92a077233ca87bd"
let OAUTH_PORT = 5165
let OAUTH_SCOPES  = [
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
//        clientID: String,
//        redirectURI: String,
//        scopes: [String],
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
        
        // librespot has it's own cache for credentials
        client.useKeychain = false

        // PKCE support
        client.clientConfig.useProofKeyForCodeExchange = true

        // Generate the full authorization URL
//        do {
//            let authURL = try client.authorizeURL(
//                withRedirect: redirectURL, scope: scopes.joined(separator: " "), params: [:])
//            print("Browse to: \(authURL.absoluteString)")
//
//            // Open the authorization URL in a browser
//            if let url = URL(string: authURL.absoluteString) {
//                openBrowser(url)
//            }
//        } catch {
//            completion(.failure(.authorizationError("Failed to create authorization URL")))
//            return
//        }
//        client.authorize { response, error in
//            if let error = error {
//                completion(.failure(error))
//            }
//        }

        // Start the HTTP server to listen for the authorization code
        startLocalHTTPServer(redirectURL: redirectURL) { result in
            switch result {
            case .success(let code):
                // Exchange the code for an access token
                client.exchangeCodeForToken(code);
//                client.handleRedirectURL(URL(string: redirectURI) ?? <#default value#>)

            case .failure(let error):
                completion(.failure(OAuth2Error.unableToOpenAuthorizeURL))
            }
        }
        
//        switch result {
//        case .success(let token):
//            guard let accessToken = token.accessToken, let tokenType = token.tokenType
//            else {
//                completion(.failure(.tokenExchangeError("Invalid token response")))
//                return
//            }
//
//            let refreshToken = token.refreshToken ?? ""
//            let expiresAt = token.expiry ?? Date().addingTimeInterval(3600)
//            let scopes = token.scope?.components(separatedBy: " ") ?? []
//
//            let oauthToken = OAuthToken(
//                accessToken: accessToken,
//                refreshToken: refreshToken,
//                expiresAt: expiresAt,
//                tokenType: tokenType,
//                scopes: scopes
//            )
//
//            completion(.success(oauthToken))
//
//        case .failure(let error):
//            completion(.failure(.tokenExchangeError(error.localizedDescription)))
//        }
        
        client.authorize { authParameters, error in
            if let params = authParameters {
                print("Authorized! Access token is: \(client.accessToken ?? "none")")
                // Handle successful authorization
            }
            else if let error = error {
                completion(.failure(error))
                // Handle error
            }
        }
        
        
    }

    // Start a simple local HTTP server to listen for the redirect URI
    func startLocalHTTPServer(
        redirectURL: URL, completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let port = NWEndpoint.Port(String(OAUTH_PORT)) else {
            return completion(.failure(NWError.posix(.EINVAL)))
        }
        let listener = try! NWListener(using: .tcp, on: port)  // You can customize the port if needed
        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Server is ready and listening on port \(OAUTH_PORT)")
            default:
                break
            }
        }

        listener.newConnectionHandler = { newConnection in
            newConnection.start(queue: .main)
            newConnection.receiveMessage { (data, context, isComplete, error) in
                if let data = data, let requestString = String(data: data, encoding: .utf8) {
                    // Check if the request contains the authorization code
                    if let code = self.extractAuthCode(from: requestString) {
                        completion(.success(code))
                        newConnection.cancel()
                        listener.cancel()  // Stop the server once the code is received
                    }
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }

        listener.start(queue: .main)
    }

    // Function to extract the authorization code from the HTTP request
    func extractAuthCode(from request: String) -> String? {
        guard let range = request.range(of: "code=") else { return nil }
        let codePart = request[range.upperBound...]
        return String(codePart.split(separator: "&").first ?? "")
    }

    func login() async throws {
        guard let core = self.core else {
            throw LoginError(message: "Core not initialized")
        }
        let result = await core.login()
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
