//
//  AuthenticationData.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 27/12/2024.
//

import AppAuth
import Combine
import Foundation
import VLogging

enum AuthenticationStateError: Error {
    /// Throws when the refresh token operation fails. Assume that the user is not authenticated anymore.
    case failedToRefreshTokens(Error?)

    /// Failed to decode the persisted state back.
    case decodingError(Error?)
}

/// A wrapper for the authentication state's data.
///
/// The abstraction is mainly for testing purposes. The API has been designed to be in conjunction
/// with the `AppAuth's OIDAuthState` class.
class AuthenticationData: NSObject, Codable {
    /// Invokes subscribers when the state changes. Usually happens during refreshing tokens.
    var stateChangedPublisher: AnyPublisher<Void, Never> { fatalError() }

    var isAuthorized: Bool {
        fatalError()
    }

    /// Returns fresh access token to be used for API requests.
    ///
    /// - throws: `AuthenticationStateError.failedToRefreshTokens` if the
    /// refresh operation fails for any reason.
    func getFreshTokens() async throws -> String {
        fatalError()
    }

    override init() { }

    required init(from decoder: any Decoder) throws {
        fatalError()
    }
}

class AppAuthAuthenticationData: AuthenticationData {
    private enum CodingKeys: String, CodingKey {
        case state
    }

    private let stateChangedSubject: PassthroughSubject<Void, Never> = .init()
    override var stateChangedPublisher: AnyPublisher<Void, Never> {
        stateChangedSubject.eraseToAnyPublisher()
    }

    private var state: OIDAuthState {
        didSet {
            stateChangedSubject.send()
        }
    }

    override var isAuthorized: Bool {
        state.isAuthorized
    }

    init(state: OIDAuthState) {
        self.state = state
        super.init()
        state.stateChangeDelegate = self
    }

    required init(from decoder: any Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let data = try container.decode(Data.self, forKey: .state)
            guard let state = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) else {
                logger.error("Failed to decode OIDAuthState: Failed to unarchive data")
                throw AuthenticationStateError.decodingError(nil)
            }
            self.state = state
        } catch {
            logger.error("Failed to decode OIDAuthState: \(error)")
            throw AuthenticationStateError.decodingError(error)
        }
        super.init()
        state.stateChangeDelegate = self
    }

    override func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
        try container.encode(data, forKey: .state)
    }

    override func getFreshTokens() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            state.performAction { accessToken, clientID, error in
                guard error == nil else {
                    logger.error("Failed to refresh tokens: \(error!)")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(error))
                    return
                }
                guard let accessToken else {
                    logger.error("Failed to refresh tokens: No access token returned. An unexpected situation.")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(nil))
                    return
                }
                continuation.resume(returning: accessToken)
            }
        }
    }
}

extension AppAuthAuthenticationData: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        logger.info("OIDAuthState changed - isAuthorized: \(state.isAuthorized)")
        stateChangedSubject.send()
    }
}
