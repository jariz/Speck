//
//  Spotify.swift
//  Speck
//
//  Created by Jari on 30/04/2023.
//

import AppKit
import Foundation
import SpotifyWebAPI
import Vapor
import KeychainAccess
import Combine

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

final class Spotify: ObservableObject {
    @Published var player: Player?
    
    private var core = SpeckCore()
    
    static let shared = Spotify()
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    static let authorizationManagerKey = "authorizationManager"
    
    /// The URL that Spotify will redirect to after the user either authorizes
    /// or denies authorization for your application.
    static let loginCallbackURL = URL(
        string: "http://127.0.0.1:\(OAUTH_PORT)/login"
    )!
    
    var authorizationState = String.randomURLSafe(length: 128)
    var codeVerifier: String
    var codeChallenge: String
    
    /**
     Whether or not the application has been authorized. If `true`, then you can
     begin making requests to the Spotify web API using the `api` property of
     this class, which contains an instance of `SpotifyAPI`.

     This property provides a convenient way for the user interface to be
     updated based on whether the user has logged in with their Spotify account
     yet. For example, you could use this property disable UI elements that
     require the user to be logged in.

     This property is updated by `authorizationManagerDidChange()`, which is
     called every time the authorization information changes, and
     `authorizationManagerDidDeauthorize()`, which is called every time
     `SpotifyAPI.authorizationManager.deauthorize()` is called.
     */
    @Published var isAuthorized = false
    
    /// The keychain to store the authorization information in.
    private let keychain = Keychain(service: "io.jari.Speck").accessibility(.whenUnlocked)
    
    /// An instance of `SpotifyAPI` that you use to make requests to the Spotify
    /// web API.
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowPKCEManager(
            clientId: OAUTH_CLIENT_ID
        )
    )
    
    var cancellables: [AnyCancellable] = []


    init() {
        self.codeVerifier = String.randomURLSafe(length: 128)
        self.codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)
        
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are updating the
            // @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        
        // Check to see if the authorization information is saved in the
        // keychain.
        if let authManagerData = keychain[data: Self.authorizationManagerKey] {
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowPKCEManager.self,
                    from: authManagerData
                )
                
                /*
                 This assignment causes `authorizationManagerDidChange` to emit
                 a signal, meaning that `authorizationManagerDidChange()` will
                 be called.

                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line, then
                 `authorizationManagerDidChange()` would not have been called
                 and the @Published `isAuthorized` property would not have been
                 properly updated.

                 We do not need to update `self.isAuthorized` here because that
                 is already handled in `authorizationManagerDidChange()`.
                 */
                self.api.authorizationManager = authorizationManager
                
            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did not find authorization information in keychain")
        }
    }
    
    func authorize() async throws {
        let authorizationURL = api.authorizationManager.makeAuthorizationURL(
            redirectURI: Self.loginCallbackURL,
            codeChallenge: self.codeChallenge,
            state: self.authorizationState,
            scopes: Scope.makeSet(OAUTH_SCOPES.joined(separator: ","))
        )!
        
        NSWorkspace.shared.open(authorizationURL)
        
        let code = try await receiveAuthCode()
        
        try await withCheckedThrowingContinuation { continuation in
            api.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: code,
                // Must match the code verifier that was used to generate the
                // code challenge when creating the authorization URL.
                codeVerifier: codeVerifier,
                // Must match the value used when creating the authorization URL.
                state: authorizationState
            )
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                    continuation.resume()
                    case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
            .store(in: &cancellables)
        }
    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.

     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires
     after an hour) this method will be called.

     It will also be called after the access and refresh tokens are retrieved
     using `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
     */
    func authorizationManagerDidChange() {
        let isExpired = self.api.authorizationManager.accessTokenIsExpired()

        if isExpired {
            // manually refresh token if it's expired because our core needs a fresh one
            self.api.authorizationManager.refreshTokens(onlyIfExpired: true)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { result in
                    // todo do something with error
                    self.authorizationManagerDidChange()
                })
                .store(in: &cancellables)
        }

        // Update the @Published `isAuthorized` property.
        self.isAuthorized = !isExpired && self.api.authorizationManager.isAuthorized()
        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(self.api.authorizationManager)
            
            // Save the data to the keychain.
            self.keychain[data: Self.authorizationManagerKey] = authManagerData
            
        } catch {
            print(
                "couldn't encode authorizationManager for storage in the " +
                "keychain:\n\(error)"
            )
        }
        
        if self.isAuthorized && !isExpired && self.player == nil {
            Task {
//                 TODO do something with error!
                await self.core.login(api.authorizationManager.accessToken!)
                // TODO background thread updates ardgfr;dg[fd
                self.player = Player(core: core, api: api)
            }
        }
    }
    
    /**
     Removes `api.authorizationManager` from the keychain.
     
     This method is called every time `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
        
        self.isAuthorized = false
        
        // TODO properly log out core?
        self.player = nil
        
        do {
            /*
             Remove the authorization information from the keychain.

             If you don't do this, then the authorization information that you
             just removed from memory by calling `deauthorize()` will be
             retrieved again from persistent storage after this app is quit and
             relaunched.
             */
            try self.keychain.remove(Self.authorizationManagerKey)
            print("did remove authorization manager from keychain")
            
        } catch {
            print(
                "couldn't remove authorization manager from keychain: \(error)"
            )
        }
    }
    
    func receiveAuthCode() async throws -> URL  {
        let app = try await Application.make()
        app.http.server.configuration.port = OAUTH_PORT
        
        return try await withCheckedThrowingContinuation { continuation in
           app.get("login") { req -> Response in
               guard let query = req.url.query,
                     let url = URL(string: "\(Spotify.loginCallbackURL.absoluteString)?\(query)") else {
                   return Response(status: .badRequest)
               }

               DispatchQueue.main.async {
                   app.server.shutdown()
                   continuation.resume(returning: url)
               }

               return Response(status: .ok, body: "You can cmd+tab back to Speck and close this window.")
           }
           
            do {
                try app.server.start()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
