//
//  SpeckSpotifyAuthorizationManager.swift
//  Speck
//
//  Created by Jari on 29/04/2023.
//

import Foundation
import SpotifyWebAPI
import Combine

enum SpeckAuthManagerError: Error {
    case speckNotInitialized
}

public class SpeckAuthManager: SpotifyAuthorizationManager {
    public init(
        accessToken: String,
        expirationDate: Date,
        speck: Speck
    ) {
        self.accessToken = accessToken
        self.expirationDate = expirationDate
        self.speck = speck
        self.didDeauthorize = PassthroughSubject()
        self.didChange = PassthroughSubject()
        self.scopes = []
    }
    
    public required init(from decoder: Decoder) throws {
        let codingWrapper = try AuthInfo(from: decoder)
        self.accessToken = codingWrapper.accessToken
        self.expirationDate = codingWrapper.expirationDate
        self.didDeauthorize = PassthroughSubject()
        self.didChange = PassthroughSubject()
        self.scopes = []
    }
    
    public func encode(to encoder: Encoder) throws {
        
        let codingWrapper = AuthInfo(
            accessToken: self.accessToken,
            refreshToken: nil,
            expirationDate: self.expirationDate,
            scopes: []
        )
        try codingWrapper.encode(to: encoder)
        
    }
 
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.accessToken)
        hasher.combine(self.expirationDate)
    }
    
    public var speck: Speck?
    
    public var accessToken: String?
    
    public var expirationDate: Date?
    
    public var scopes: Set<SpotifyWebAPI.Scope>
    
    public var didChange: PassthroughSubject<Void, Never>
    
    public var didDeauthorize: PassthroughSubject<Void, Never>
    
    public func accessTokenIsExpired(tolerance: Double) -> Bool {
        if self.accessToken == nil { return true }
        guard let expirationDate = self.expirationDate else { return true }
        return expirationDate.addingTimeInterval(-tolerance) <= Date()
    }
    
    public func refreshTokens(onlyIfExpired: Bool, tolerance: Double) -> AnyPublisher<Void, Error> {
        if onlyIfExpired, !self.accessTokenIsExpired(tolerance: tolerance) {
            return Result.Publisher(()).eraseToAnyPublisher()
        }
        
        return Future { promise in
            async {
                do {
                    guard let speck = self.speck else { return promise(.failure(SpeckAuthManagerError.speckNotInitialized)) }
                    let token = await speck.get_token()
                    self.accessToken = token.access_token.toString();
                    self.expirationDate = SpeckAuthManager.dateFromSeconds(seconds: token.expires_in)
                    self.didChange.send(())
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
//        return Future<Void, Error> { promise in
//            Task {
//                guard let speck = self.speck else { return promise(.failure(SpeckAuthManagerError.speckNotInitialized)) }
//                let token = await speck.get_token()
//                self.accessToken = token.access_token.toString();
//                self.expirationDate = SpeckAuthManager.dateFromSeconds(seconds: token.expires_in)
//                self.didChange.send(())
//                promise(.success(()))
//            }
//        }
//        .eraseToAnyPublisher()
    }
    
    public func isAuthorized(for scopes: Set<SpotifyWebAPI.Scope>) -> Bool {
        return self.accessToken != nil
    }
    
    public func deauthorize() {
        self.accessToken = nil
        self.expirationDate = nil
        self.didDeauthorize.send(())
    }
    
    public func _assertNotOnUpdateAuthInfoDispatchQueue() {
        
    }
    
    static public func dateFromSeconds (seconds: UInt32) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(integerLiteral: Int64(seconds)))
    }
}
